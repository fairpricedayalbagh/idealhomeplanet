import { Router } from "express";
import { getLatestVersion } from "../services/app.service.js";

export const appRoutes = Router();

// GET /api/app/version — Public, no auth required
// Returns latest app version info from GitHub Releases
appRoutes.get("/version", async (_req, res, next) => {
  try {
    const data = await getLatestVersion();

    if (!data) {
      res.status(503).json({
        success: false,
        error: "Version info temporarily unavailable",
      });
      return;
    }

    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
});
