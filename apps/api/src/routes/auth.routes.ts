import { Router } from "express";
import { authenticate } from "../middleware/auth.js";
import { login, refreshTokens, logout, AppError } from "../services/auth.service.js";
import { loginSchema } from "@ihp/shared";

export const authRoutes = Router();

// POST /api/auth/login — Phone + PIN → JWT
authRoutes.post("/login", async (req, res, next) => {
  try {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ success: false, error: "Invalid input", details: parsed.error.flatten() });
      return;
    }

    const result = await login(parsed.data.phone, parsed.data.pin);
    res.json({ success: true, data: result });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});

// POST /api/auth/refresh — Refresh token
authRoutes.post("/refresh", async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      res.status(400).json({ success: false, error: "Refresh token required" });
      return;
    }

    const result = await refreshTokens(refreshToken);
    res.json({ success: true, data: result });
  } catch (err) {
    if (err instanceof AppError) {
      res.status(err.statusCode).json({ success: false, error: err.message, code: err.code });
      return;
    }
    next(err);
  }
});

// POST /api/auth/logout — Revoke refresh token
authRoutes.post("/logout", authenticate, async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await logout(refreshToken);
    }
    res.json({ success: true, message: "Logged out" });
  } catch (err) {
    next(err);
  }
});
