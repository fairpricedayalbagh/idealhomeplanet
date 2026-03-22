import "dotenv/config";

export const config = {
  PORT: parseInt(process.env.PORT || "3000", 10),
  DATABASE_URL: process.env.DATABASE_URL || "",
  JWT_SECRET: process.env.JWT_SECRET || "dev-secret-change-me",
  JWT_REFRESH_SECRET:
    process.env.JWT_REFRESH_SECRET || "dev-refresh-secret-change-me",
  JWT_ACCESS_EXPIRY: process.env.JWT_ACCESS_EXPIRY || "15m",
  JWT_REFRESH_EXPIRY: process.env.JWT_REFRESH_EXPIRY || "7d",
  TZ: process.env.TZ || "Asia/Kolkata",
  PIN_MAX_ATTEMPTS: parseInt(process.env.PIN_MAX_ATTEMPTS || "5", 10),
  PIN_LOCKOUT_MINS: parseInt(process.env.PIN_LOCKOUT_MINS || "30", 10),
  CRON_SECRET: process.env.CRON_SECRET || "",
  NODE_ENV: process.env.NODE_ENV || "development",
  IS_VERCEL: !!process.env.VERCEL,
};
