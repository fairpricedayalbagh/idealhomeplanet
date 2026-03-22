import cron from "node-cron";
import { prisma } from "../utils/prisma.js";

// Auto-checkout employees who forgot to check out
export function startAutoCheckoutJob() {
  // Run at 23:59 every day
  cron.schedule("59 23 * * *", async () => {
    try {
      console.log("[CRON] Running auto-checkout...");

      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      // Find employees who checked in today but haven't checked out
      const checkedInUsers = await prisma.attendance.findMany({
        where: {
          type: "CHECK_IN",
          timestamp: { gte: today, lt: tomorrow },
        },
        select: { userId: true, timestamp: true },
      });

      const checkOuts = await prisma.attendance.findMany({
        where: {
          type: "CHECK_OUT",
          timestamp: { gte: today, lt: tomorrow },
        },
        select: { userId: true },
      });

      const checkedOutUserIds = new Set(checkOuts.map((r: { userId: string }) => r.userId));
      const needAutoCheckout = checkedInUsers.filter((r: { userId: string }) => !checkedOutUserIds.has(r.userId));

      let count = 0;
      for (const record of needAutoCheckout) {
        // Get employee's shift end time
        const user = await prisma.user.findUnique({
          where: { id: record.userId },
          select: { shiftEnd: true },
        });

        if (!user) continue;

        const [endH, endM] = user.shiftEnd.split(":").map(Number);
        const checkoutTime = new Date(today);
        checkoutTime.setHours(endH, endM, 0, 0);

        await prisma.attendance.create({
          data: {
            userId: record.userId,
            type: "CHECK_OUT",
            timestamp: checkoutTime,
            isManual: true,
            note: "Auto-checkout: employee forgot to check out",
          },
        });
        count++;
      }

      console.log(`[CRON] Auto-checkout complete: ${count} employees checked out`);
    } catch (err) {
      console.error("[CRON] Auto-checkout failed:", err);
    }
  });

  console.log("[CRON] Auto-checkout job scheduled (daily at 23:59)");
}
