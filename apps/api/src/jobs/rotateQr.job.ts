import cron from "node-cron";
import { rotateQr } from "../services/qr.service.js";

// Rotate QR token daily at midnight
export function startQrRotationJob() {
  cron.schedule("0 0 * * *", async () => {
    try {
      console.log("[CRON] Rotating QR token...");
      const token = await rotateQr();
      console.log(`[CRON] QR token rotated: ${token.id} for date ${token.date.toISOString().split("T")[0]}`);
    } catch (err) {
      console.error("[CRON] QR rotation failed:", err);
    }
  });

  console.log("[CRON] QR rotation job scheduled (daily at midnight)");
}
