import { Router } from "express";
import { authenticate, requireRole } from "../middleware/auth.js";
import { markAttendanceSchema, manualAttendanceSchema } from "@ihp/shared";
import * as attendanceService from "../services/attendance.service.js";
import { createAuditLog } from "../services/audit.service.js";
import { AppError } from "../services/auth.service.js";

export const attendanceRoutes = Router();

// POST /api/attendance/mark — Scan QR → mark check-in/out
attendanceRoutes.post("/mark", authenticate, requireRole("EMPLOYEE"), async (req, res, next) => {
  try {
    const parsed = markAttendanceSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: "Invalid input", details: parsed.error.flatten() });
      return;
    }

    const record = await attendanceService.markAttendance(req.user!.userId, parsed.data);
    res.status(201).json({ success: true, data: record });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});

// POST /api/attendance/manual — Admin adds/corrects attendance
attendanceRoutes.post("/manual", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const parsed = manualAttendanceSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: "Invalid input", details: parsed.error.flatten() });
      return;
    }

    const record = await attendanceService.addManualAttendance(req.user!.userId, parsed.data);

    await createAuditLog({
      userId: req.user!.userId,
      action: "MANUAL_ATTENDANCE",
      entityType: "Attendance",
      entityId: record.id,
      details: { targetUser: parsed.data.userId, type: parsed.data.type, note: parsed.data.note },
    });

    res.status(201).json({ success: true, data: record });
  } catch (err) {
    next(err);
  }
});

// GET /api/attendance/my — Employee's own attendance history
attendanceRoutes.get("/my", authenticate, requireRole("EMPLOYEE"), async (req, res, next) => {
  try {
    const month = req.query.month ? parseInt(req.query.month as string) : undefined;
    const year = req.query.year ? parseInt(req.query.year as string) : undefined;
    const page = req.query.page ? parseInt(req.query.page as string) : undefined;
    const limit = req.query.limit ? parseInt(req.query.limit as string) : undefined;

    const result = await attendanceService.getMyAttendance(req.user!.userId, { month, year, page, limit });
    res.json({ success: true, data: result.records, total: result.total, page: result.page, limit: result.limit });
  } catch (err) {
    next(err);
  }
});

// GET /api/attendance/all — All employees' attendance
attendanceRoutes.get("/all", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const result = await attendanceService.getAllAttendance({
      userId: req.query.userId as string | undefined,
      startDate: req.query.startDate as string | undefined,
      endDate: req.query.endDate as string | undefined,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    res.json({ success: true, data: result.records, total: result.total, page: result.page, limit: result.limit });
  } catch (err) {
    next(err);
  }
});

// GET /api/attendance/today — Today's live attendance board
attendanceRoutes.get("/today", authenticate, requireRole("ADMIN"), async (_req, res, next) => {
  try {
    const board = await attendanceService.getTodayAttendance();
    res.json({ success: true, data: board });
  } catch (err) {
    next(err);
  }
});

// GET /api/attendance/report — Monthly attendance summary
attendanceRoutes.get("/report", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const month = parseInt(req.query.month as string);
    const year = parseInt(req.query.year as string);

    if (!month || !year || month < 1 || month > 12) {
      res.status(400).json({ success: false, error: "Valid month and year required" });
      return;
    }

    const report = await attendanceService.getAttendanceReport(month, year);
    res.json({ success: true, data: report });
  } catch (err) {
    next(err);
  }
});
