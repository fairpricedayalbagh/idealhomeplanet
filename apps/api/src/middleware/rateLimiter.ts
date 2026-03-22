import type { Request, Response, NextFunction } from "express";

const requests = new Map<string, { count: number; resetAt: number }>();

const WINDOW_MS = 60 * 1000; // 1 minute
const MAX_REQUESTS = 60;

export function rateLimiter(req: Request, res: Response, next: NextFunction) {
  const key = req.ip || "unknown";
  const now = Date.now();

  const entry = requests.get(key);

  if (!entry || now > entry.resetAt) {
    requests.set(key, { count: 1, resetAt: now + WINDOW_MS });
    next();
    return;
  }

  entry.count++;

  if (entry.count > MAX_REQUESTS) {
    res.status(429).json({ success: false, error: "Too many requests" });
    return;
  }

  next();
}
