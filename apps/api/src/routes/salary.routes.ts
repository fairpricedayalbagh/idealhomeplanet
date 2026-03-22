import { Router } from "express";
import { authenticate, requireRole } from "../middleware/auth.js";
import { generateSalarySchema } from "@ihp/shared";
import * as salaryService from "../services/salary.service.js";
import { createAuditLog } from "../services/audit.service.js";
import { AppError } from "../services/auth.service.js";

export const salaryRoutes = Router();

// GET /api/salary/my — Employee's salary slips
salaryRoutes.get("/my", authenticate, requireRole("EMPLOYEE"), async (req, res, next) => {
  try {
    const slips = await salaryService.getMySalarySlips(req.user!.userId);
    res.json({ success: true, data: slips });
  } catch (err) {
    next(err);
  }
});

// GET /api/salary/all — All salary slips
salaryRoutes.get("/all", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const result = await salaryService.getAllSalarySlips({
      month: req.query.month ? parseInt(req.query.month as string) : undefined,
      year: req.query.year ? parseInt(req.query.year as string) : undefined,
      status: req.query.status as string | undefined,
      userId: req.query.userId as string | undefined,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    res.json({ success: true, data: result.slips, total: result.total, page: result.page, limit: result.limit });
  } catch (err) {
    next(err);
  }
});

// POST /api/salary/generate — Trigger salary generation
salaryRoutes.post("/generate", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const parsed = generateSalarySchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: "Invalid input", details: parsed.error.flatten() });
      return;
    }

    const results = await salaryService.generateSalaries(parsed.data.month, parsed.data.year);

    await createAuditLog({
      userId: req.user!.userId,
      action: "SALARY_GENERATED",
      entityType: "SalarySlip",
      entityId: `${parsed.data.month}-${parsed.data.year}`,
      details: { month: parsed.data.month, year: parsed.data.year, results },
    });

    res.json({ success: true, data: results });
  } catch (err) {
    next(err);
  }
});

// PUT /api/salary/:id/pay — Mark slip as paid
salaryRoutes.put("/:id/pay", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const { paymentMode } = req.body;
    if (!paymentMode || !["CASH", "BANK", "UPI"].includes(paymentMode)) {
      res.status(400).json({ success: false, error: "Valid paymentMode required (CASH, BANK, UPI)" });
      return;
    }

    const slip = await salaryService.markAsPaid(req.params.id, paymentMode);

    await createAuditLog({
      userId: req.user!.userId,
      action: "SALARY_PAID",
      entityType: "SalarySlip",
      entityId: req.params.id,
      details: { paymentMode },
    });

    res.json({ success: true, data: slip });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});

// PUT /api/salary/:id/bonus — Add ad-hoc bonus
salaryRoutes.put("/:id/bonus", authenticate, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const { amount } = req.body;
    if (typeof amount !== "number" || amount <= 0) {
      res.status(400).json({ success: false, error: "Positive amount required" });
      return;
    }

    const slip = await salaryService.addBonus(req.params.id, amount);

    await createAuditLog({
      userId: req.user!.userId,
      action: "BONUS_ADDED",
      entityType: "SalarySlip",
      entityId: req.params.id,
      details: { amount },
    });

    res.json({ success: true, data: slip });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});

// GET /api/salary/:id/pdf — Download salary slip PDF
salaryRoutes.get("/:id/pdf", authenticate, async (req, res, next) => {
  try {
    const slip = await salaryService.getSalarySlip(req.params.id);

    // Verify employee can only access their own slip
    if (req.user!.role === "EMPLOYEE" && slip.userId !== req.user!.userId) {
      res.status(403).json({ success: false, error: "Forbidden" });
      return;
    }

    // Return slip data (PDF generation can be handled by a dedicated library later)
    res.json({
      success: true,
      data: slip,
      message: "PDF generation endpoint — integrate with a PDF library (e.g., pdfkit) for actual PDF output",
    });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});
