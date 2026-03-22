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

  // Calculate total leave days excluding off-days
  const offDays = (user.weeklyOffDays as number[]) ?? [0];
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

  // Check balance for non-unpaid leave
  if (data.leaveType !== "UNPAID") {
    const balanceField = getBalanceField(data.leaveType);
    const balance = user[balanceField] as number;
    if (balance < totalDays) {
      throw new AppError(
        `Insufficient ${data.leaveType.toLowerCase()} leave balance. Available: ${balance}, Requested: ${totalDays}`,
        400,
        "INSUFFICIENT_LEAVE"
      );
    }
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
  const [leaves, user] = await Promise.all([
    prisma.leave.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
    }),
    prisma.user.findUnique({
      where: { id: userId },
      select: {
        sickLeaveBalance: true,
        casualLeaveBalance: true,
        paidLeaveBalance: true,
      },
    }),
  ]);

  return {
    leaves,
    balances: user
      ? {
          sick: user.sickLeaveBalance,
          casual: user.casualLeaveBalance,
          paid: user.paidLeaveBalance,
        }
      : null,
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

  // Deduct leave balance if not unpaid
  if (leave.leaveType !== "UNPAID") {
    const balanceField = getBalanceField(leave.leaveType);
    await prisma.user.update({
      where: { id: leave.userId },
      data: { [balanceField]: { decrement: leave.totalDays } },
    });
  }

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

function getBalanceField(leaveType: "SICK" | "CASUAL" | "PAID"): "sickLeaveBalance" | "casualLeaveBalance" | "paidLeaveBalance" {
  switch (leaveType) {
    case "SICK": return "sickLeaveBalance";
    case "CASUAL": return "casualLeaveBalance";
    case "PAID": return "paidLeaveBalance";
  }
}
