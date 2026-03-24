import { Router } from "express";
import { authenticate, requireRole } from "../middleware/auth.js";
import { applyAdvanceSchema, approveAdvanceSchema } from "@ihp/shared";
import * as advanceService from "../services/advance.service.js";
import { createAuditLog } from "../services/audit.service.js";
import { AppError } from "../services/auth.service.js";

export const advanceRoutes = Router();

// POST /api/advance/apply — Employee applies for salary advance
advanceRoutes.post("/apply", authenticate, requireRole("EMPLOYEE"), async (req, res, next) => {
  try {
    const parsed = applyAdvanceSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: "Invalid input", details: parsed.error.flatten() });
      return;
    }

    const advance = await advanceService.applyAdvance(req.user!.userId, parsed.data);
    res.status(201).json({ success: true, data: advance });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});

// GET /api/advance/my — Employee's advance history
advanceRoutes.get("/my", authenticate, requireRole("EMPLOYEE"), async (req, res, next) => {
  try {
    const advances = await advanceService.getMyAdvances(req.user!.userId);
    res.json({ success: true, data: advances });
  } catch (err) {
    next(err);
  }
});

// GET /api/advance/all — All advance requests (Admin)
advanceRoutes.get("/all", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const result = await advanceService.getAllAdvances({
      status: req.query.status as string | undefined,
      userId: req.query.userId as string | undefined,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    res.json({ success: true, data: result.advances, total: result.total, page: result.page, limit: result.limit });
  } catch (err) {
    next(err);
  }
});

// GET /api/advance/pending — Pending advance requests (Admin)
advanceRoutes.get("/pending", authenticate, requireRole("ADMIN"), async (_req, res, next) => {
  try {
    const advances = await advanceService.getPendingAdvances();
    res.json({ success: true, data: advances });
  } catch (err) {
    next(err);
  }
});

// PUT /api/advance/:id/approve — Approve advance (Admin can modify amount)
advanceRoutes.put("/:id/approve", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const parsed = approveAdvanceSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: "Invalid input", details: parsed.error.flatten() });
      return;
    }

    const advance = await advanceService.approveAdvance(
      req.params.id,
      req.user!.userId,
      parsed.data.approvedAmount,
      parsed.data.reviewNote
    );

    await createAuditLog({
      userId: req.user!.userId,
      action: "ADVANCE_APPROVED",
      entityType: "AdvanceRequest",
      entityId: req.params.id,
      details: {
        requestedAmount: advance.requestedAmount,
        approvedAmount: advance.approvedAmount,
        deductMonth: advance.deductMonth,
        deductYear: advance.deductYear,
      },
    });

    res.json({ success: true, data: advance });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});

// PUT /api/advance/:id/reject — Reject advance (Admin)
advanceRoutes.put("/:id/reject", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const advance = await advanceService.rejectAdvance(
      req.params.id,
      req.user!.userId,
      req.body.reviewNote
    );

    await createAuditLog({
      userId: req.user!.userId,
      action: "ADVANCE_REJECTED",
      entityType: "AdvanceRequest",
      entityId: req.params.id,
      details: { reason: req.body.reviewNote },
    });

    res.json({ success: true, data: advance });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});
