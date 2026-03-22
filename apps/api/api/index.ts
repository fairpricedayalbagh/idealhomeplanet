// @ts-nocheck
let handler;

try {
  const mod = await import("../dist/app.mjs");
  handler = mod.app;
} catch (err) {
  // Diagnostic: expose the boot error so we can debug on Vercel
  handler = (_req, res) => {
    res.status(500).json({
      error: "Failed to load app",
      message: err?.message || String(err),
      stack: err?.stack?.split("\n").slice(0, 10),
    });
  };
}

export default handler;
