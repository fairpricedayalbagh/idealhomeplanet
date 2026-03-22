import express from "express";
import cors from "cors";
import { errorHandler } from "./middleware/errorHandler.js";
import { rateLimiter } from "./middleware/rateLimiter.js";
import { routes } from "./routes/index.js";

const app = express();

app.use(cors());
app.use(express.json());
app.use(rateLimiter);

// All routes mounted under /api
app.use("/api", routes);

// Health check
app.get("/api/health", (_req, res) => {
  res.json({ success: true, status: "ok", timestamp: new Date().toISOString() });
});

app.use(errorHandler);

export { app };
