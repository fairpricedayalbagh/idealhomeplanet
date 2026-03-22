// Minimal diagnostic — no imports, just return info about the environment
export default function handler(req: any, res: any) {
  const fs = require("fs");
  const path = require("path");

  const checks: Record<string, any> = {};

  // Check what directory we're in
  checks.cwd = process.cwd();
  checks.__dirname = __dirname;

  // Check if dist exists
  const distPath = path.join(__dirname, "..", "dist");
  checks.distExists = fs.existsSync(distPath);
  if (checks.distExists) {
    checks.distFiles = fs.readdirSync(distPath);
  }

  // Check if node_modules exists nearby
  checks.localNodeModules = fs.existsSync(path.join(__dirname, "..", "node_modules"));
  checks.rootNodeModules = fs.existsSync(path.join(__dirname, "..", "..", "..", "node_modules"));

  // Check if src exists
  const srcPath = path.join(__dirname, "..", "src");
  checks.srcExists = fs.existsSync(srcPath);

  // Check for @ihp/shared
  try {
    const sharedPath = require.resolve("@ihp/shared");
    checks.sharedResolved = sharedPath;
  } catch (e: any) {
    checks.sharedError = e.message;
  }

  // Check for express
  try {
    const expressPath = require.resolve("express");
    checks.expressResolved = expressPath;
  } catch (e: any) {
    checks.expressError = e.message;
  }

  // Check for @prisma/client
  try {
    const prismaPath = require.resolve("@prisma/client");
    checks.prismaResolved = prismaPath;
  } catch (e: any) {
    checks.prismaError = e.message;
  }

  res.status(200).json(checks);
}
