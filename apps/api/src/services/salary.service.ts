import { prisma } from "../utils/prisma.js";
import { AppError } from "./auth.service.js";
import { getHolidaysInRange } from "./holiday.service.js";

type UserRecord = {
  id: string; name: string; dateOfJoining: Date;
  weeklyOffDays: unknown; shiftStart: string; shiftEnd: string; graceMins: number;
  salaryType: string; monthlySalary: number | null; hourlyRate: number | null;
  [key: string]: unknown;
};
type LeaveRecord = { startDate: Date; endDate: Date; leaveType: string; totalDays: number; [key: string]: unknown };

export async function generateSalaries(month: number, year: number) {
  const employees = await prisma.user.findMany({
    where: { role: "EMPLOYEE", isActive: true },
  });

  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 0); // last day of month
  const daysInMonth = endDate.getDate();

  const holidays = await getHolidaysInRange(startDate, new Date(year, month, 0, 23, 59, 59));
  const holidayDates = new Set<string>(holidays.map((h: { date: Date }) => h.date.toISOString().split("T")[0]));

  const results: Array<{ userId: string; name: string; status: string }> = [];

  for (const emp of employees) {
    // Check if salary already generated for this month
    const existing = await prisma.salarySlip.findUnique({
      where: { userId_month_year: { userId: emp.id, month, year } },
    });

    if (existing) {
      results.push({ userId: emp.id, name: emp.name, status: "already_generated" });
      continue;
    }

    try {
      const data = await calculateSalaryDetails(emp, month, year, startDate, endDate, daysInMonth, holidayDates);
      await prisma.salarySlip.create({ data });
      results.push({ userId: emp.id, name: emp.name, status: "generated" });
    } catch (err) {
      results.push({ userId: emp.id, name: emp.name, status: `error: ${(err as Error).message}` });
    }
  }

  return results;
}

export async function previewSalary(userId: string, month: number, year: number) {
  const emp = await prisma.user.findUnique({
    where: { id: userId, role: "EMPLOYEE", isActive: true },
  });
  if (!emp) throw new AppError("Active employee not found", 404, "NOT_FOUND");

  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 0);
  const daysInMonth = endDate.getDate();
  const holidays = await getHolidaysInRange(startDate, new Date(year, month, 0, 23, 59, 59));
  const holidayDates = new Set<string>(holidays.map((h: { date: Date }) => h.date.toISOString().split("T")[0]));

  const details = await calculateSalaryDetails(emp, month, year, startDate, endDate, daysInMonth, holidayDates);
  return details;
}

export async function generateSingleSalary(
  userId: string,
  month: number,
  year: number,
  overrides?: {
    bonus?: number;
    deductions?: number;
    grossAmount?: number;
    netAmount?: number;
  }
) {
  const existing = await prisma.salarySlip.findUnique({
    where: { userId_month_year: { userId, month, year } },
  });
  if (existing) throw new AppError("Salary already generated for this month", 400, "EXISTS");

  const details = await previewSalary(userId, month, year);

  // Apply overrides
  if (overrides) {
    if (overrides.bonus !== undefined) details.bonus = overrides.bonus;
    if (overrides.deductions !== undefined) details.deductions = overrides.deductions;
    if (overrides.grossAmount !== undefined) details.grossAmount = overrides.grossAmount;
    
    // Recalculate net if anything changed and netAmount wasn't explicitly overridden
    if (overrides.netAmount !== undefined) {
      details.netAmount = overrides.netAmount;
    } else {
      details.netAmount = details.grossAmount + details.bonus - details.deductions;
    }
  }

  return prisma.salarySlip.create({ data: details });
}

export async function getMonthStatus(month: number, year: number) {
  const employees = await prisma.user.findMany({
    where: { role: "EMPLOYEE", isActive: true },
    select: { id: true, name: true, phone: true, designation: true },
    orderBy: { name: "asc" }
  });

  const slips = await prisma.salarySlip.findMany({
    where: { month, year },
  });

  const slipMap = new Map(slips.map(s => [s.userId, s]));

  return employees.map(emp => ({
    user: emp,
    slip: slipMap.get(emp.id) || null,
  }));
}

export async function calculateSalaryDetails(
  emp: UserRecord,
  month: number,
  year: number,
  startDate: Date,
  endDate: Date,
  daysInMonth: number,
  holidayDates: Set<string>
) {
  const offDays = (emp.weeklyOffDays as number[]) ?? [0];

  // Determine effective start date (for mid-month joining)
  const joiningDate = new Date(emp.dateOfJoining);
  const effectiveStart = joiningDate > startDate ? joiningDate : startDate;

  // Calculate working days in month
  let workingDaysInMonth = 0;
  for (let d = new Date(effectiveStart); d <= endDate; d.setDate(d.getDate() + 1)) {
    const dateStr = d.toISOString().split("T")[0];
    if (!offDays.includes(d.getDay()) && !holidayDates.has(dateStr)) {
      workingDaysInMonth++;
    }
  }

  if (workingDaysInMonth === 0) workingDaysInMonth = 1; // avoid division by zero

  // Fetch approved leaves for this month
  const approvedLeaves = await prisma.leave.findMany({
    where: {
      userId: emp.id,
      status: "APPROVED",
      startDate: { lte: endDate },
      endDate: { gte: startDate },
    },
  });

  // Count leave days in this month
  let paidLeaveDays = 0;
  let unpaidLeaveDays = 0;
  for (const leave of approvedLeaves) {
    const leaveStart = leave.startDate > startDate ? leave.startDate : startDate;
    const leaveEnd = leave.endDate < endDate ? leave.endDate : endDate;
    const current = new Date(leaveStart);
    while (current <= leaveEnd) {
      const dateStr = current.toISOString().split("T")[0];
      if (!offDays.includes(current.getDay()) && !holidayDates.has(dateStr)) {
        if (leave.leaveType === "UNPAID") {
          unpaidLeaveDays++;
        } else {
          paidLeaveDays++;
        }
      }
      current.setDate(current.getDate() + 1);
    }
  }

  const totalLeaveDays = paidLeaveDays + unpaidLeaveDays;

  // Fetch attendance records
  const attendance = await prisma.attendance.findMany({
    where: {
      userId: emp.id,
      timestamp: { gte: effectiveStart, lte: new Date(endDate.getTime() + 86400000) },
    },
    orderBy: { timestamp: "asc" },
  });

  // Group attendance by date
  const byDate = new Map<string, Array<{ type: string; timestamp: Date }>>();
  for (const rec of attendance) {
    const dateKey = rec.timestamp.toISOString().split("T")[0];
    const existing = byDate.get(dateKey) ?? [];
    existing.push({ type: rec.type, timestamp: rec.timestamp });
    byDate.set(dateKey, existing);
  }

  // Parse shift times
  const [shiftStartH, shiftStartM] = emp.shiftStart.split(":").map(Number);
  const [shiftEndH, shiftEndM] = emp.shiftEnd.split(":").map(Number);
  const shiftHours = (shiftEndH + shiftEndM / 60) - (shiftStartH + shiftStartM / 60);

  let daysPresent = 0;
  let daysLate = 0;
  let daysAbsent = 0;
  let totalHours = 0;
  let overtimeHours = 0;
  let latePenalty = 0;

  // Process each working day
  for (let d = new Date(effectiveStart); d <= endDate; d.setDate(d.getDate() + 1)) {
    const dateStr = d.toISOString().split("T")[0];

    // Skip off-days and holidays
    if (offDays.includes(d.getDay()) || holidayDates.has(dateStr)) continue;

    // Skip approved leave days
    const isLeaveDay = approvedLeaves.some((leave: LeaveRecord) => {
      const ls = leave.startDate.toISOString().split("T")[0];
      const le = leave.endDate.toISOString().split("T")[0];
      return dateStr >= ls && dateStr <= le;
    });
    if (isLeaveDay) continue;

    const dayRecords = byDate.get(dateStr);
    if (!dayRecords || !dayRecords.find((r) => r.type === "CHECK_IN")) {
      daysAbsent++;
      continue;
    }

    const checkIn = dayRecords.find((r) => r.type === "CHECK_IN");
    const checkOut = dayRecords.find((r) => r.type === "CHECK_OUT");
    daysPresent++;

    // Check for late
    if (checkIn) {
      const ciTime = checkIn.timestamp;
      const graceDeadline = new Date(ciTime);
      graceDeadline.setHours(shiftStartH, shiftStartM + emp.graceMins, 0, 0);

      if (ciTime > graceDeadline) {
        daysLate++;
        const shiftStartTime = new Date(ciTime);
        shiftStartTime.setHours(shiftStartH, shiftStartM, 0, 0);
        const lateMinutes = (ciTime.getTime() - shiftStartTime.getTime()) / 60000;

        if (emp.salaryType === "HOURLY" && emp.hourlyRate) {
          latePenalty += (lateMinutes / 60) * emp.hourlyRate * 0.5;
        } else if (emp.salaryType === "MONTHLY" && emp.monthlySalary) {
          latePenalty += (lateMinutes / 60) * (emp.monthlySalary / workingDaysInMonth / shiftHours) * 0.5;
        }
      }
    }

    // Calculate hours worked
    if (checkIn && checkOut) {
      const hours = (checkOut.timestamp.getTime() - checkIn.timestamp.getTime()) / 3600000;
      totalHours += hours;

      // Overtime
      if (hours > shiftHours) {
        overtimeHours += hours - shiftHours;
      }
    }
  }

  // Calculate gross amount
  let grossAmount = 0;
  if (emp.salaryType === "HOURLY" && emp.hourlyRate) {
    grossAmount = totalHours * emp.hourlyRate;
  } else if (emp.salaryType === "MONTHLY" && emp.monthlySalary) {
    const perDayRate = emp.monthlySalary / workingDaysInMonth;
    grossAmount = (daysPresent + paidLeaveDays) * perDayRate;
  }

  // Build deduction breakdown
  const perDayRate = emp.salaryType === "MONTHLY" && emp.monthlySalary
    ? emp.monthlySalary / workingDaysInMonth
    : 0;

  const deductionBreakdown: Record<string, number> = {};
  if (latePenalty > 0) deductionBreakdown.late_penalty = Math.round(latePenalty * 100) / 100;
  if (daysAbsent > 0 && perDayRate > 0) {
    deductionBreakdown.absent_deduction = Math.round(daysAbsent * perDayRate * 100) / 100;
  }
  if (unpaidLeaveDays > 0 && perDayRate > 0) {
    deductionBreakdown.unpaid_leave = Math.round(unpaidLeaveDays * perDayRate * 100) / 100;
  }

  const totalDeductions = Object.values(deductionBreakdown).reduce((sum, v) => sum + v, 0);
  const netAmount = grossAmount - totalDeductions;

  return {
    userId: emp.id,
    month,
    year,
    totalDays: daysPresent,
    totalHours: Math.round(totalHours * 100) / 100,
    overtimeHours: Math.round(overtimeHours * 100) / 100,
    daysAbsent,
    daysLate,
    leaveDays: totalLeaveDays,
    grossAmount: Math.round(grossAmount * 100) / 100,
    deductionBreakdown,
    deductions: Math.round(totalDeductions * 100) / 100,
    netAmount: Math.round(netAmount * 100) / 100,
    bonus: 0,
  };
}

export async function getMySalarySlips(userId: string) {
  return prisma.salarySlip.findMany({
    where: { userId },
    orderBy: [{ year: "desc" }, { month: "desc" }],
  });
}

export async function getAllSalarySlips(filters: {
  month?: number;
  year?: number;
  status?: string;
  userId?: string;
  page?: number;
  limit?: number;
}) {
  const { page = 1, limit = 50 } = filters;
  const where: Record<string, unknown> = {};

  if (filters.month) where.month = filters.month;
  if (filters.year) where.year = filters.year;
  if (filters.status) where.status = filters.status;
  if (filters.userId) where.userId = filters.userId;

  const [slips, total] = await Promise.all([
    prisma.salarySlip.findMany({
      where,
      include: { user: { select: { id: true, name: true, phone: true, designation: true } } },
      orderBy: [{ year: "desc" }, { month: "desc" }],
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.salarySlip.count({ where }),
  ]);

  return { slips, total, page, limit };
}

export async function markAsPaid(slipId: string, paymentMode: "CASH" | "BANK" | "UPI") {
  const slip = await prisma.salarySlip.findUnique({ where: { id: slipId } });
  if (!slip) throw new AppError("Salary slip not found", 404, "NOT_FOUND");
  if (slip.status === "PAID") throw new AppError("Already paid", 400, "VALIDATION_ERROR");

  return prisma.salarySlip.update({
    where: { id: slipId },
    data: { status: "PAID", paymentMode, paidAt: new Date() },
  });
}

export async function addBonus(slipId: string, amount: number) {
  const slip = await prisma.salarySlip.findUnique({ where: { id: slipId } });
  if (!slip) throw new AppError("Salary slip not found", 404, "NOT_FOUND");

  return prisma.salarySlip.update({
    where: { id: slipId },
    data: {
      bonus: slip.bonus + amount,
      netAmount: slip.netAmount + amount,
    },
  });
}

export async function getSalarySlip(slipId: string) {
  const slip = await prisma.salarySlip.findUnique({
    where: { id: slipId },
    include: { user: { select: { id: true, name: true, phone: true, designation: true, bankAccount: true, bankIfsc: true, upiId: true } } },
  });
  if (!slip) throw new AppError("Salary slip not found", 404, "NOT_FOUND");
  return slip;
}
