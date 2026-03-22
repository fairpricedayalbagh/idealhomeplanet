import { Router } from "express";
import { authenticate, requireRole } from "../middleware/auth.js";
import { getAuditLogs } from "../services/audit.service.js";

export const auditRoutes = Router();

// GET /api/audit-log — View audit trail
auditRoutes.get("/", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const result = await getAuditLogs({
      userId: req.query.userId as string | undefined,
      action: req.query.action as string | undefined,
      entityType: req.query.entityType as string | undefined,
      entityId: req.query.entityId as string | undefined,
      startDate: req.query.startDate as string | undefined,
      endDate: req.query.endDate as string | undefined,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });

    res.json({
      success: true,
      data: result.logs,
      total: result.total,
      page: result.page,
      limit: result.limit,
    });
  } catch (err) {
    next(err);
  }
});
