import { Router } from "express";
import { authenticate, requireRole } from "../middleware/auth.js";
import * as qrService from "../services/qr.service.js";
import { createAuditLog } from "../services/audit.service.js";

export const qrRoutes = Router();

// GET /api/qr/today — Get today's QR as base64 PNG
qrRoutes.get("/today", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const qr = await qrService.getTodayQr();
    res.json({ success: true, data: qr });
  } catch (err) {
    next(err);
  }
});

// POST /api/qr/rotate — Force-rotate QR now
qrRoutes.post("/rotate", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const qrToken = await qrService.rotateQr();

    await createAuditLog({
      userId: req.user!.userId,
      action: "QR_ROTATED",
      entityType: "QrToken",
      entityId: qrToken.id,
    });

    res.json({ success: true, data: { id: qrToken.id, date: qrToken.date, expiresAt: qrToken.expiresAt } });
  } catch (err) {
    next(err);
  }
});
