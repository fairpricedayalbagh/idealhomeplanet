import cron from "node-cron";
import { generateSalaries } from "../services/salary.service.js";

// Auto-generate salaries on the 1st of every month at 2 AM
export function startSalaryGenerationJob() {
  cron.schedule("0 2 1 * *", async () => {
    try {
      // Generate for the previous month
      const now = new Date();
      let month = now.getMonth(); // 0-indexed, so current month - 1 = previous month
      let year = now.getFullYear();

      if (month === 0) {
        month = 12;
        year -= 1;
      }

      console.log(`[CRON] Generating salaries for ${month}/${year}...`);
      const results = await generateSalaries(month, year);
      console.log(`[CRON] Salary generation complete:`, results);
    } catch (err) {
      console.error("[CRON] Salary generation failed:", err);
    }
  });

  console.log("[CRON] Salary generation job scheduled (1st of month at 2 AM)");
}
