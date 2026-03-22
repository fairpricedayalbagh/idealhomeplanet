import { prisma } from "../utils/prisma.js";
import { hashPin } from "../utils/hash.js";
import type { CreateEmployeeRequest, UpdateEmployeeRequest } from "@ihp/shared";

const userSelectFields = {
  id: true,
  name: true,
  phone: true,
  email: true,
  role: true,
  isActive: true,
  profilePhoto: true,
  designation: true,
  dateOfBirth: true,
  dateOfJoining: true,
  address: true,
  emergencyName: true,
  emergencyPhone: true,
  salaryType: true,
  monthlySalary: true,
  hourlyRate: true,
  bankAccount: true,
  bankIfsc: true,
  upiId: true,
  sickLeaveBalance: true,
  casualLeaveBalance: true,
  paidLeaveBalance: true,
  shiftStart: true,
  shiftEnd: true,
  graceMins: true,
  weeklyOffDays: true,
  createdAt: true,
  updatedAt: true,
};

export async function listEmployees(filters?: {
  search?: string;
  isActive?: boolean;
}) {
  const where: Record<string, unknown> = { role: "EMPLOYEE" };

  if (filters?.isActive !== undefined) {
    where.isActive = filters.isActive;
  }

  if (filters?.search) {
    where.OR = [
      { name: { contains: filters.search, mode: "insensitive" } },
      { phone: { contains: filters.search } },
      { designation: { contains: filters.search, mode: "insensitive" } },
    ];
  }

  return prisma.user.findMany({
    where,
    select: userSelectFields,
    orderBy: { name: "asc" },
  });
}

export async function getEmployee(id: string) {
  return prisma.user.findUnique({
    where: { id },
    select: userSelectFields,
  });
}

export async function createEmployee(data: CreateEmployeeRequest) {
  const hashedPin = await hashPin(data.pin);

  return prisma.user.create({
    data: {
      name: data.name,
      phone: data.phone,
      email: data.email,
      pin: hashedPin,
      role: "EMPLOYEE",
      designation: data.designation,
      dateOfJoining: data.dateOfJoining ? new Date(data.dateOfJoining) : undefined,
      dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : undefined,
      address: data.address,
      emergencyName: data.emergencyName,
      emergencyPhone: data.emergencyPhone,
      bankAccount: data.bankAccount,
      bankIfsc: data.bankIfsc,
      upiId: data.upiId,
      salaryType: data.salaryType,
      monthlySalary: data.monthlySalary,
      hourlyRate: data.hourlyRate,
      shiftStart: data.shiftStart,
      shiftEnd: data.shiftEnd,
      graceMins: data.graceMins,
      weeklyOffDays: data.weeklyOffDays ?? [0],
      sickLeaveBalance: data.sickLeaveBalance,
      casualLeaveBalance: data.casualLeaveBalance,
      paidLeaveBalance: data.paidLeaveBalance,
    },
    select: userSelectFields,
  });
}

export async function updateEmployee(id: string, data: UpdateEmployeeRequest) {
  const updateData: Record<string, unknown> = {};

  if (data.name !== undefined) updateData.name = data.name;
  if (data.phone !== undefined) updateData.phone = data.phone;
  if (data.email !== undefined) updateData.email = data.email;
  if (data.designation !== undefined) updateData.designation = data.designation;
  if (data.address !== undefined) updateData.address = data.address;
  if (data.emergencyName !== undefined) updateData.emergencyName = data.emergencyName;
  if (data.emergencyPhone !== undefined) updateData.emergencyPhone = data.emergencyPhone;
  if (data.bankAccount !== undefined) updateData.bankAccount = data.bankAccount;
  if (data.bankIfsc !== undefined) updateData.bankIfsc = data.bankIfsc;
  if (data.upiId !== undefined) updateData.upiId = data.upiId;
  if (data.salaryType !== undefined) updateData.salaryType = data.salaryType;
  if (data.monthlySalary !== undefined) updateData.monthlySalary = data.monthlySalary;
  if (data.hourlyRate !== undefined) updateData.hourlyRate = data.hourlyRate;
  if (data.shiftStart !== undefined) updateData.shiftStart = data.shiftStart;
  if (data.shiftEnd !== undefined) updateData.shiftEnd = data.shiftEnd;
  if (data.graceMins !== undefined) updateData.graceMins = data.graceMins;
  if (data.weeklyOffDays !== undefined) updateData.weeklyOffDays = data.weeklyOffDays;
  if (data.sickLeaveBalance !== undefined) updateData.sickLeaveBalance = data.sickLeaveBalance;
  if (data.casualLeaveBalance !== undefined) updateData.casualLeaveBalance = data.casualLeaveBalance;
  if (data.paidLeaveBalance !== undefined) updateData.paidLeaveBalance = data.paidLeaveBalance;
  if (data.dateOfJoining !== undefined) updateData.dateOfJoining = new Date(data.dateOfJoining);
  if (data.dateOfBirth !== undefined) updateData.dateOfBirth = new Date(data.dateOfBirth);

  if (data.pin) {
    updateData.pin = await hashPin(data.pin);
  }

  return prisma.user.update({
    where: { id },
    data: updateData,
    select: userSelectFields,
  });
}

export async function updateShift(id: string, data: {
  shiftStart?: string;
  shiftEnd?: string;
  graceMins?: number;
}) {
  return prisma.user.update({
    where: { id },
    data,
    select: userSelectFields,
  });
}

export async function updateSalaryConfig(id: string, data: {
  salaryType?: "MONTHLY" | "HOURLY";
  monthlySalary?: number;
  hourlyRate?: number;
}) {
  return prisma.user.update({
    where: { id },
    data,
    select: userSelectFields,
  });
}

export async function updateOffDays(id: string, weeklyOffDays: number[]) {
  return prisma.user.update({
    where: { id },
    data: { weeklyOffDays },
    select: userSelectFields,
  });
}

export async function resetPin(id: string, newPin: string) {
  const hashedPin = await hashPin(newPin);
  return prisma.user.update({
    where: { id },
    data: { pin: hashedPin, pinAttempts: 0, lockedUntil: null },
    select: userSelectFields,
  });
}

export async function deactivateEmployee(id: string) {
  return prisma.user.update({
    where: { id },
    data: { isActive: false },
    select: userSelectFields,
  });
}
