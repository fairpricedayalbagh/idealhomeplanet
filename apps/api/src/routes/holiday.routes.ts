import { Router } from "express";
import { authenticate, requireRole } from "../middleware/auth.js";
import * as holidayService from "../services/holiday.service.js";
import { createAuditLog } from "../services/audit.service.js";

export const holidayRoutes = Router();

// GET /api/holidays — List holidays for the year
holidayRoutes.get("/", authenticate, async (req, res, next) => {
  try {
    const year = req.query.year ? parseInt(req.query.year as string) : new Date().getFullYear();
    const holidays = await holidayService.getHolidays(year);
    res.json({ success: true, data: holidays });
  } catch (err) {
    next(err);
  }
});

// POST /api/holidays — Add a holiday
holidayRoutes.post("/", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const { name, date, isOptional } = req.body;
    if (!name || !date) {
      res.status(400).json({ success: false, error: "name and date are required" });
      return;
    }

    const holiday = await holidayService.addHoliday({ name, date, isOptional });

    await createAuditLog({
      userId: req.user!.userId,
      action: "HOLIDAY_CREATED",
      entityType: "Holiday",
      entityId: holiday.id,
      details: { name, date },
    });

    res.status(201).json({ success: true, data: holiday });
  } catch (err) {
    if ((err as { code?: string }).code === "P2002") {
      res.status(409).json({ success: false, error: "A holiday already exists on this date" });
      return;
    }
    next(err);
  }
});

// DELETE /api/holidays/:id — Remove a holiday
holidayRoutes.delete("/:id", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    await holidayService.deleteHoliday(req.params.id);

    await createAuditLog({
      userId: req.user!.userId,
      action: "HOLIDAY_DELETED",
      entityType: "Holiday",
      entityId: req.params.id,
    });

    res.json({ success: true, message: "Holiday deleted" });
  } catch (err) {
    if ((err as { code?: string }).code === "P2025") {
      res.status(404).json({ success: false, error: "Holiday not found" });
      return;
    }
    next(err);
  }
});
