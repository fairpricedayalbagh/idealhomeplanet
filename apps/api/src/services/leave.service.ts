import { prisma } from "../utils/prisma.js";
import { AppError } from "./auth.service.js";

export async function applyLeave(
  userId: string,
  data: { leaveType: "SICK" | "CASUAL" | "PAID" | "UNPAID"; startDate: string; endDate: string; reason: string }
) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new AppError("User not found", 404, "NOT_FOUND");

  const start = new Date(data.startDate);
  const end = new Date(data.endDate);

  if (end < start) {
    throw new AppError("End date must be after start date", 400, "VALIDATION_ERROR");
  }

  // Count leave days (all days count — no weekly off exclusions in this store)
  const offDays = (user.weeklyOffDays as number[]) ?? [];
  let totalDays = 0;
  const current = new Date(start);
  while (current <= end) {
    if (!offDays.includes(current.getDay())) {
      totalDays++;
    }
    current.setDate(current.getDate() + 1);
  }

  if (totalDays === 0) {
    throw new AppError("No working days in selected range", 400, "VALIDATION_ERROR");
  }

  // Enforce monthly leave limit
  const reqStart = new Date(data.startDate);
  const monthStart = new Date(reqStart.getFullYear(), reqStart.getMonth(), 1);
  const monthEnd = new Date(reqStart.getFullYear(), reqStart.getMonth() + 1, 0, 23, 59, 59);

  const approvedThisMonth = await prisma.leave.findMany({
    where: {
      userId,
      status: "APPROVED",
      startDate: { gte: monthStart, lte: monthEnd },
    },
  });
  const usedThisMonth = approvedThisMonth.reduce((sum, l) => sum + l.totalDays, 0);
  const monthlyCredits = user.monthlyLeaveCredits ?? 4;

  if (usedThisMonth + totalDays > monthlyCredits) {
    throw new AppError(
      `Leave limit exceeded. You have ${monthlyCredits - usedThisMonth} leave${monthlyCredits - usedThisMonth === 1 ? "" : "s"} remaining this month.`,
      400,
      "LEAVE_LIMIT_EXCEEDED"
    );
  }

  return prisma.leave.create({
    data: {
      userId,
      leaveType: data.leaveType,
      startDate: start,
      endDate: end,
      totalDays,
      reason: data.reason,
    },
  });
}

export async function getMyLeaves(userId: string) {
  const now = new Date();
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

  const [leaves, user] = await Promise.all([
    prisma.leave.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
    }),
    prisma.user.findUnique({
      where: { id: userId },
      select: { monthlyLeaveCredits: true },
    }),
  ]);

  // Count approved leave days taken this month
  const usedThisMonth = leaves
    .filter((l) => l.status === "APPROVED" && l.startDate >= monthStart && l.startDate <= monthEnd)
    .reduce((sum, l) => sum + l.totalDays, 0);

  const monthlyCredits = user?.monthlyLeaveCredits ?? 4;

  return {
    leaves,
    balances: {
      monthlyCredits,
      usedThisMonth,
      remaining: Math.max(0, monthlyCredits - usedThisMonth),
    },
  };
}

export async function getAllLeaves(filters: {
  status?: string;
  userId?: string;
  page?: number;
  limit?: number;
}) {
  const { page = 1, limit = 50 } = filters;
  const where: Record<string, unknown> = {};

  if (filters.status) where.status = filters.status;
  if (filters.userId) where.userId = filters.userId;

  const [leaves, total] = await Promise.all([
    prisma.leave.findMany({
      where,
      include: { user: { select: { id: true, name: true, phone: true, designation: true } } },
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.leave.count({ where }),
  ]);

  return { leaves, total, page, limit };
}

export async function getPendingLeaves() {
  return prisma.leave.findMany({
    where: { status: "PENDING" },
    include: { user: { select: { id: true, name: true, phone: true, designation: true } } },
    orderBy: { createdAt: "asc" },
  });
}

export async function approveLeave(leaveId: string, adminId: string, reviewNote?: string) {
  const leave = await prisma.leave.findUnique({ where: { id: leaveId } });
  if (!leave) throw new AppError("Leave not found", 404, "NOT_FOUND");
  if (leave.status !== "PENDING") {
    throw new AppError("Leave already reviewed", 400, "VALIDATION_ERROR");
  }

  // No balance deduction — salary calculation handles the leave cost/credit logic
  return prisma.leave.update({
    where: { id: leaveId },
    data: {
      status: "APPROVED",
      reviewedBy: adminId,
      reviewedAt: new Date(),
      reviewNote,
    },
  });
}

export async function rejectLeave(leaveId: string, adminId: string, reviewNote?: string) {
  const leave = await prisma.leave.findUnique({ where: { id: leaveId } });
  if (!leave) throw new AppError("Leave not found", 404, "NOT_FOUND");
  if (leave.status !== "PENDING") {
    throw new AppError("Leave already reviewed", 400, "VALIDATION_ERROR");
  }

  return prisma.leave.update({
    where: { id: leaveId },
    data: {
      status: "REJECTED",
      reviewedBy: adminId,
      reviewedAt: new Date(),
      reviewNote,
    },
  });
}
