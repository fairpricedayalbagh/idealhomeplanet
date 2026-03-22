// Import from pre-compiled output (tsup/esbuild, no TS type-checking needed)
import { app } from "../dist/app.mjs";

// Vercel serverless handler — export Express app as default
// Vercel wraps it automatically via @vercel/node
export default app;
