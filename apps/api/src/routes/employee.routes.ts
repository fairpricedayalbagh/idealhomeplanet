import { Router } from "express";
import { authenticate, requireRole } from "../middleware/auth.js";
import { createEmployeeSchema } from "@ihp/shared";
import * as employeeService from "../services/employee.service.js";
import { createAuditLog } from "../services/audit.service.js";
import { AppError } from "../services/auth.service.js";

export const employeeRoutes = Router();

const adminOnly = [authenticate, requireRole("ADMIN")] as const;

// GET /api/employees — List all employees
employeeRoutes.get("/", ...adminOnly, async (req, res, next) => {
  try {
    const search = req.query.search as string | undefined;
    const isActive = req.query.isActive === undefined ? undefined : req.query.isActive === "true";
    const employees = await employeeService.listEmployees({ search, isActive });
    res.json({ success: true, data: employees });
  } catch (err) {
    next(err);
  }
});

// POST /api/employees — Add employee
employeeRoutes.post("/", ...adminOnly, async (req, res, next) => {
  try {
    const parsed = createEmployeeSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: "Invalid input", details: parsed.error.flatten() });
      return;
    }

    const employee = await employeeService.createEmployee(parsed.data);

    await createAuditLog({
      userId: req.user!.userId,
      action: "EMPLOYEE_CREATED",
      entityType: "User",
      entityId: employee.id,
      details: { name: employee.name, phone: employee.phone },
    });

    res.status(201).json({ success: true, data: employee });
  } catch (err) {
    if ((err as { code?: string }).code === "P2002") {
      res.status(409).json({ success: false, error: "Phone number already registered" });
      return;
    }
    next(err);
  }
});

// PUT /api/employees/:id — Edit employee
employeeRoutes.put("/:id", ...adminOnly, async (req, res, next) => {
  try {
    const employee = await employeeService.updateEmployee(req.params.id, req.body);

    await createAuditLog({
      userId: req.user!.userId,
      action: "EMPLOYEE_UPDATED",
      entityType: "User",
      entityId: req.params.id,
      details: { fields: Object.keys(req.body) },
    });

    res.json({ success: true, data: employee });
  } catch (err) {
    if ((err as { code?: string }).code === "P2025") {
      res.status(404).json({ success: false, error: "Employee not found" });
      return;
    }
    next(err);
  }
});

// PUT /api/employees/:id/shift — Update shift times
employeeRoutes.put("/:id/shift", ...adminOnly, async (req, res, next) => {
  try {
    const employee = await employeeService.updateShift(req.params.id, req.body);

    await createAuditLog({
      userId: req.user!.userId,
      action: "SHIFT_UPDATED",
      entityType: "User",
      entityId: req.params.id,
      details: req.body,
    });

    res.json({ success: true, data: employee });
  } catch (err) {
    if ((err as { code?: string }).code === "P2025") {
      res.status(404).json({ success: false, error: "Employee not found" });
      return;
    }
    next(err);
  }
});

// PUT /api/employees/:id/salary — Update salary config
employeeRoutes.put("/:id/salary", ...adminOnly, async (req, res, next) => {
  try {
    const employee = await employeeService.updateSalaryConfig(req.params.id, req.body);

    await createAuditLog({
      userId: req.user!.userId,
      action: "SALARY_CONFIG_UPDATED",
      entityType: "User",
      entityId: req.params.id,
      details: req.body,
    });

    res.json({ success: true, data: employee });
  } catch (err) {
    if ((err as { code?: string }).code === "P2025") {
      res.status(404).json({ success: false, error: "Employee not found" });
      return;
    }
    next(err);
  }
});

// PUT /api/employees/:id/offdays — Update weekly off-days
employeeRoutes.put("/:id/offdays", ...adminOnly, async (req, res, next) => {
  try {
    const { weeklyOffDays } = req.body;
    if (!Array.isArray(weeklyOffDays)) {
      res.status(400).json({ success: false, error: "weeklyOffDays must be an array" });
      return;
    }

    const employee = await employeeService.updateOffDays(req.params.id, weeklyOffDays);

    await createAuditLog({
      userId: req.user!.userId,
      action: "OFFDAYS_UPDATED",
      entityType: "User",
      entityId: req.params.id,
      details: { weeklyOffDays },
    });

    res.json({ success: true, data: employee });
  } catch (err) {
    if ((err as { code?: string }).code === "P2025") {
      res.status(404).json({ success: false, error: "Employee not found" });
      return;
    }
    next(err);
  }
});

// PUT /api/employees/:id/reset-pin — Reset employee PIN
employeeRoutes.put("/:id/reset-pin", ...adminOnly, async (req, res, next) => {
  try {
    const { pin } = req.body;
    if (!pin || !/^\d{4}$/.test(pin)) {
      res.status(400).json({ success: false, error: "PIN must be a 4-digit number" });
      return;
    }

    const employee = await employeeService.resetPin(req.params.id, pin);

    await createAuditLog({
      userId: req.user!.userId,
      action: "PIN_RESET",
      entityType: "User",
      entityId: req.params.id,
    });

    res.json({ success: true, data: employee });
  } catch (err) {
    if ((err as { code?: string }).code === "P2025") {
      res.status(404).json({ success: false, error: "Employee not found" });
      return;
    }
    next(err);
  }
});

// DELETE /api/employees/:id — Deactivate employee
employeeRoutes.delete("/:id", ...adminOnly, async (req, res, next) => {
  try {
    const employee = await employeeService.deactivateEmployee(req.params.id);

    await createAuditLog({
      userId: req.user!.userId,
      action: "EMPLOYEE_DEACTIVATED",
      entityType: "User",
      entityId: req.params.id,
    });

    res.json({ success: true, data: employee });
  } catch (err) {
    if ((err as { code?: string }).code === "P2025") {
      res.status(404).json({ success: false, error: "Employee not found" });
      return;
    }
    next(err);
  }
});
