import { prisma } from "../utils/prisma.js";
import { validateQrToken } from "./qr.service.js";
import { AppError } from "./auth.service.js";

type AttendanceRecord = { type: string; timestamp: Date; userId: string; [key: string]: unknown };
type EmployeeSelect = { id: string; name: string; phone: string; designation: string | null; shiftStart: string; shiftEnd: string; graceMins: number; weeklyOffDays: unknown };

export async function markAttendance(
  userId: string,
  data: { qrToken: string; type: "CHECK_IN" | "CHECK_OUT"; deviceId?: string }
) {
  // Validate QR token
  const qrToken = await validateQrToken(data.qrToken);
  if (!qrToken) {
    throw new AppError("Invalid or expired QR code", 400, "QR_INVALID");
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  // Get today's attendance for this user
  const todayAttendance = await prisma.attendance.findMany({
    where: {
      userId,
      timestamp: { gte: today, lt: tomorrow },
    },
    orderBy: { timestamp: "desc" },
  });

  if (data.type === "CHECK_IN") {
    // Check if already checked in without checking out
    const lastRecord = todayAttendance[0];
    if (lastRecord && lastRecord.type === "CHECK_IN") {
      throw new AppError(
        "Already checked in. Please check out first.",
        400,
        "ALREADY_CHECKED_IN"
      );
    }
  } else {
    // CHECK_OUT — must have a CHECK_IN first
    const lastRecord = todayAttendance[0];
    if (!lastRecord || lastRecord.type !== "CHECK_IN") {
      throw new AppError(
        "Not checked in. Please check in first.",
        400,
        "NOT_CHECKED_IN"
      );
    }
  }

  return prisma.attendance.create({
    data: {
      userId,
      type: data.type,
      qrTokenId: qrToken.id,
      deviceId: data.deviceId,
    },
  });
}

export async function addManualAttendance(
  adminId: string,
  data: { userId: string; type: "CHECK_IN" | "CHECK_OUT"; timestamp: string; note: string }
) {
  return prisma.attendance.create({
    data: {
      userId: data.userId,
      type: data.type,
      timestamp: new Date(data.timestamp),
      isManual: true,
      addedBy: adminId,
      note: data.note,
    },
  });
}

export async function getMyAttendance(
  userId: string,
  filters: { month?: number; year?: number; page?: number; limit?: number }
) {
  const { page = 1, limit = 50 } = filters;
  const where: Record<string, unknown> = { userId };

  if (filters.month && filters.year) {
    const startDate = new Date(filters.year, filters.month - 1, 1);
    const endDate = new Date(filters.year, filters.month, 0, 23, 59, 59);
    where.timestamp = { gte: startDate, lte: endDate };
  }

  const [records, total] = await Promise.all([
    prisma.attendance.findMany({
      where,
      orderBy: { timestamp: "desc" },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.attendance.count({ where }),
  ]);

  return { records, total, page, limit };
}

export async function getAllAttendance(filters: {
  userId?: string;
  startDate?: string;
  endDate?: string;
  page?: number;
  limit?: number;
}) {
  const { page = 1, limit = 50 } = filters;
  const where: Record<string, unknown> = {};

  if (filters.userId) where.userId = filters.userId;

  if (filters.startDate || filters.endDate) {
    const timestamp: Record<string, Date> = {};
    if (filters.startDate) timestamp.gte = new Date(filters.startDate);
    if (filters.endDate) timestamp.lte = new Date(filters.endDate);
    where.timestamp = timestamp;
  }

  const [records, total] = await Promise.all([
    prisma.attendance.findMany({
      where,
      include: { user: { select: { id: true, name: true, phone: true, designation: true } } },
      orderBy: { timestamp: "desc" },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.attendance.count({ where }),
  ]);

  return { records, total, page, limit };
}

export async function getTodayAttendance() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  // Get all active employees
  const employees = await prisma.user.findMany({
    where: { role: "EMPLOYEE", isActive: true },
    select: { id: true, name: true, phone: true, designation: true, shiftStart: true },
  });

  // Get all attendance records for today
  const records = await prisma.attendance.findMany({
    where: { timestamp: { gte: today, lt: tomorrow } },
    orderBy: { timestamp: "asc" },
  });

  // Map attendance by userId
  const attendanceMap = new Map<string, typeof records>();
  for (const record of records) {
    const existing = attendanceMap.get(record.userId) ?? [];
    existing.push(record);
    attendanceMap.set(record.userId, existing);
  }

  return employees.map((emp: { id: string; name: string; phone: string; designation: string | null; shiftStart: string }) => {
    const empRecords = attendanceMap.get(emp.id) ?? [];
    const checkIn = empRecords.find((r: AttendanceRecord) => r.type === "CHECK_IN");
    const checkOut = empRecords.find((r: AttendanceRecord) => r.type === "CHECK_OUT");

    let status: "present" | "absent" | "late" = "absent";
    if (checkIn) {
      const shiftParts = emp.shiftStart.split(":");
      const shiftTime = new Date(today);
      shiftTime.setHours(parseInt(shiftParts[0]), parseInt(shiftParts[1]), 0, 0);
      status = checkIn.timestamp > shiftTime ? "late" : "present";
    }

    return {
      employee: emp,
      checkIn: checkIn?.timestamp ?? null,
      checkOut: checkOut?.timestamp ?? null,
      status,
    };
  });
}

export async function getAttendanceReport(month: number, year: number) {
  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 0, 23, 59, 59);

  const employees = await prisma.user.findMany({
    where: { role: "EMPLOYEE", isActive: true },
    select: {
      id: true,
      name: true,
      phone: true,
      designation: true,
      shiftStart: true,
      shiftEnd: true,
      graceMins: true,
      weeklyOffDays: true,
    },
  });

  const allRecords = await prisma.attendance.findMany({
    where: { timestamp: { gte: startDate, lte: endDate } },
    orderBy: { timestamp: "asc" },
  });

  const recordsByUser = new Map<string, typeof allRecords>();
  for (const record of allRecords) {
    const existing = recordsByUser.get(record.userId) ?? [];
    existing.push(record);
    recordsByUser.set(record.userId, existing);
  }

  return employees.map((emp: EmployeeSelect) => {
    const records = recordsByUser.get(emp.id) ?? [];
    let daysPresent = 0;
    let daysLate = 0;
    let totalHours = 0;

    // Group records by date
    const byDate = new Map<string, typeof records>();
    for (const r of records) {
      const dateKey = r.timestamp.toISOString().split("T")[0];
      const existing = byDate.get(dateKey) ?? [];
      existing.push(r);
      byDate.set(dateKey, existing);
    }

    for (const [, dayRecords] of byDate) {
      const checkIn = dayRecords.find((r: AttendanceRecord) => r.type === "CHECK_IN");
      const checkOut = dayRecords.find((r: AttendanceRecord) => r.type === "CHECK_OUT");

      if (checkIn) {
        daysPresent++;
        const shiftParts = emp.shiftStart.split(":");
        const shiftTime = new Date(checkIn.timestamp);
        shiftTime.setHours(parseInt(shiftParts[0]), parseInt(shiftParts[1]) + emp.graceMins, 0, 0);
        if (checkIn.timestamp > shiftTime) daysLate++;

        if (checkOut) {
          totalHours += (checkOut.timestamp.getTime() - checkIn.timestamp.getTime()) / 3600000;
        }
      }
    }

    return {
      employee: emp,
      daysPresent,
      daysLate,
      totalHours: Math.round(totalHours * 100) / 100,
    };
  });
}
