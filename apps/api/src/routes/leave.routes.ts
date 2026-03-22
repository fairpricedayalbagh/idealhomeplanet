import { Router } from "express";
import { authenticate, requireRole } from "../middleware/auth.js";
import { applyLeaveSchema } from "@ihp/shared";
import * as leaveService from "../services/leave.service.js";
import { createAuditLog } from "../services/audit.service.js";
import { AppError } from "../services/auth.service.js";

export const leaveRoutes = Router();

// POST /api/leave/apply — Employee applies for leave
leaveRoutes.post("/apply", authenticate, requireRole("EMPLOYEE"), async (req, res, next) => {
  try {
    const parsed = applyLeaveSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: "Invalid input", details: parsed.error.flatten() });
      return;
    }

    const leave = await leaveService.applyLeave(req.user!.userId, parsed.data);
    res.status(201).json({ success: true, data: leave });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});

// GET /api/leave/my — Employee's leave history + balances
leaveRoutes.get("/my", authenticate, requireRole("EMPLOYEE"), async (req, res, next) => {
  try {
    const result = await leaveService.getMyLeaves(req.user!.userId);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

// GET /api/leave/all — All leave requests
leaveRoutes.get("/all", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const result = await leaveService.getAllLeaves({
      status: req.query.status as string | undefined,
      userId: req.query.userId as string | undefined,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    res.json({ success: true, data: result.leaves, total: result.total, page: result.page, limit: result.limit });
  } catch (err) {
    next(err);
  }
});

// GET /api/leave/pending — Pending leave requests
leaveRoutes.get("/pending", authenticate, requireRole("ADMIN"), async (_req, res, next) => {
  try {
    const leaves = await leaveService.getPendingLeaves();
    res.json({ success: true, data: leaves });
  } catch (err) {
    next(err);
  }
});

// PUT /api/leave/:id/approve — Approve leave
leaveRoutes.put("/:id/approve", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const leave = await leaveService.approveLeave(req.params.id, req.user!.userId, req.body.reviewNote);

    await createAuditLog({
      userId: req.user!.userId,
      action: "LEAVE_APPROVED",
      entityType: "Leave",
      entityId: req.params.id,
      details: { leaveType: leave.leaveType, totalDays: leave.totalDays },
    });

    res.json({ success: true, data: leave });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});

// PUT /api/leave/:id/reject — Reject leave
leaveRoutes.put("/:id/reject", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const leave = await leaveService.rejectLeave(req.params.id, req.user!.userId, req.body.reviewNote);

    await createAuditLog({
      userId: req.user!.userId,
      action: "LEAVE_REJECTED",
      entityType: "Leave",
      entityId: req.params.id,
      details: { leaveType: leave.leaveType, reason: req.body.reviewNote },
    });

    res.json({ success: true, data: leave });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});
