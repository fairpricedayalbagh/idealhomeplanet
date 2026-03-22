import { z } from "zod";

export const loginSchema = z.object({
  phone: z.string().min(10).max(15),
  pin: z.string().length(4).regex(/^\d{4}$/),
});

export const markAttendanceSchema = z.object({
  qrToken: z.string().uuid(),
  type: z.enum(["CHECK_IN", "CHECK_OUT"]),
  deviceId: z.string().optional(),
});

export const manualAttendanceSchema = z.object({
  userId: z.string().uuid(),
  type: z.enum(["CHECK_IN", "CHECK_OUT"]),
  timestamp: z.string().datetime(),
  note: z.string().min(1, "Reason is required"),
});

export const createEmployeeSchema = z.object({
  name: z.string().min(1),
  phone: z.string().min(10).max(15),
  email: z.string().email().optional(),
  pin: z.string().length(4).regex(/^\d{4}$/),
  designation: z.string().optional(),
  dateOfJoining: z.string().optional(),
  dateOfBirth: z.string().optional(),
  address: z.string().optional(),
  emergencyName: z.string().optional(),
  emergencyPhone: z.string().optional(),
  bankAccount: z.string().optional(),
  bankIfsc: z.string().optional(),
  upiId: z.string().optional(),
  salaryType: z.enum(["MONTHLY", "HOURLY"]),
  monthlySalary: z.number().positive().optional(),
  hourlyRate: z.number().positive().optional(),
  shiftStart: z.string().regex(/^\d{2}:\d{2}$/).optional(),
  shiftEnd: z.string().regex(/^\d{2}:\d{2}$/).optional(),
  graceMins: z.number().int().min(0).max(60).optional(),
  weeklyOffDays: z.array(z.number().int().min(0).max(6)).optional(),
  sickLeaveBalance: z.number().int().min(0).optional(),
  casualLeaveBalance: z.number().int().min(0).optional(),
  paidLeaveBalance: z.number().int().min(0).optional(),
});

export const applyLeaveSchema = z.object({
  leaveType: z.enum(["SICK", "CASUAL", "PAID", "UNPAID"]),
  startDate: z.string(),
  endDate: z.string(),
  reason: z.string().min(1, "Reason is required"),
});

export const generateSalarySchema = z.object({
  month: z.number().int().min(1).max(12),
  year: z.number().int().min(2020),
});
