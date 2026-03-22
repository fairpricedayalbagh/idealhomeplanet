import { app } from "./app.js";
import { config } from "./config/env.js";
import { startQrRotationJob } from "./jobs/rotateQr.job.js";
import { startAutoCheckoutJob } from "./jobs/autoCheckout.job.js";
import { startSalaryGenerationJob } from "./jobs/generateSalary.job.js";

const PORT = config.PORT;

app.listen(PORT, () => {
  console.log(`API server running on http://localhost:${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);

  // Start cron jobs only in standalone mode (not on Vercel)
  if (!config.IS_VERCEL) {
    startQrRotationJob();
    startAutoCheckoutJob();
    startSalaryGenerationJob();
  }
});
