import { Router } from "express";
import { authRoutes } from "./auth.routes.js";
import { qrRoutes } from "./qr.routes.js";
import { attendanceRoutes } from "./attendance.routes.js";
import { employeeRoutes } from "./employee.routes.js";
import { salaryRoutes } from "./salary.routes.js";
import { leaveRoutes } from "./leave.routes.js";
import { holidayRoutes } from "./holiday.routes.js";
import { auditRoutes } from "./audit.routes.js";

export const routes = Router();

routes.use("/auth", authRoutes);
routes.use("/qr", qrRoutes);
routes.use("/attendance", attendanceRoutes);
routes.use("/employees", employeeRoutes);
routes.use("/salary", salaryRoutes);
routes.use("/leave", leaveRoutes);
routes.use("/holidays", holidayRoutes);
routes.use("/audit-log", auditRoutes);
