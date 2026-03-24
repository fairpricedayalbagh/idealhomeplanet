import { prisma } from "../utils/prisma.js";
import { AppError } from "./auth.service.js";

export async function applyAdvance(
  userId: string,
  data: {
    requestedAmount: number;
    reason: string;
    deductMonth: number;
    deductYear: number;
  }
) {
  // Prevent duplicate pending advance for the same deduct month/year
  const existing = await prisma.advanceRequest.findFirst({
    where: {
      userId,
      deductMonth: data.deductMonth,
      deductYear: data.deductYear,
      status: "PENDING",
    },
  });
  if (existing) {
    throw new AppError(
      "You already have a pending advance request for that month",
      400,
      "VALIDATION_ERROR"
    );
  }

  return prisma.advanceRequest.create({
    data: {
      userId,
      requestedAmount: data.requestedAmount,
      reason: data.reason,
      deductMonth: data.deductMonth,
      deductYear: data.deductYear,
    },
  });
}

export async function getMyAdvances(userId: string) {
  return prisma.advanceRequest.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
  });
}

export async function getAllAdvances(filters: {
  status?: string;
  userId?: string;
  page?: number;
  limit?: number;
}) {
  const { page = 1, limit = 50 } = filters;
  const where: Record<string, unknown> = {};
  if (filters.status) where.status = filters.status;
  if (filters.userId) where.userId = filters.userId;

  const [advances, total] = await Promise.all([
    prisma.advanceRequest.findMany({
      where,
      include: {
        user: { select: { id: true, name: true, phone: true, designation: true } },
      },
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.advanceRequest.count({ where }),
  ]);

  return { advances, total, page, limit };
}

export async function getPendingAdvances() {
  return prisma.advanceRequest.findMany({
    where: { status: "PENDING" },
    include: {
      user: { select: { id: true, name: true, phone: true, designation: true } },
    },
    orderBy: { createdAt: "asc" },
  });
}

export async function approveAdvance(
  id: string,
  adminId: string,
  approvedAmount?: number,
  reviewNote?: string
) {
  const advance = await prisma.advanceRequest.findUnique({ where: { id } });
  if (!advance) throw new AppError("Advance request not found", 404, "NOT_FOUND");
  if (advance.status !== "PENDING") {
    throw new AppError("Only pending requests can be approved", 400, "VALIDATION_ERROR");
  }

  return prisma.advanceRequest.update({
    where: { id },
    data: {
      status: "APPROVED",
      approvedAmount: approvedAmount ?? advance.requestedAmount,
      reviewedBy: adminId,
      reviewedAt: new Date(),
      reviewNote,
    },
  });
}

export async function rejectAdvance(
  id: string,
  adminId: string,
  reviewNote?: string
) {
  const advance = await prisma.advanceRequest.findUnique({ where: { id } });
  if (!advance) throw new AppError("Advance request not found", 404, "NOT_FOUND");
  if (advance.status !== "PENDING") {
    throw new AppError("Only pending requests can be rejected", 400, "VALIDATION_ERROR");
  }

  return prisma.advanceRequest.update({
    where: { id },
    data: {
      status: "REJECTED",
      reviewedBy: adminId,
      reviewedAt: new Date(),
      reviewNote,
    },
  });
}
