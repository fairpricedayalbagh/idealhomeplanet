// @ts-nocheck
// Import from pre-compiled tsup output to avoid Express type issues
import { app } from "../dist/app.mjs";

// Vercel serverless handler
export default app;
