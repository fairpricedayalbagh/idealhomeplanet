import { prisma } from "../utils/prisma.js";
import { hashPin, comparePin } from "../utils/hash.js";
import { signAccessToken, signRefreshToken, verifyRefreshToken } from "../utils/jwt.js";
import { config } from "../config/env.js";
import { randomBytes } from "crypto";

export async function login(phone: string, pin: string) {
  const user = await prisma.user.findUnique({ where: { phone } });

  if (!user || !user.isActive) {
    throw new AppError("Invalid credentials", 401, "INVALID_CREDENTIALS");
  }

  // Check lockout
  if (user.lockedUntil && user.lockedUntil > new Date()) {
    const remainingMins = Math.ceil((user.lockedUntil.getTime() - Date.now()) / 60000);
    throw new AppError(
      `Account locked. Try again in ${remainingMins} minutes`,
      423,
      "ACCOUNT_LOCKED"
    );
  }

  const pinValid = await comparePin(pin, user.pin);

  if (!pinValid) {
    const attempts = user.pinAttempts + 1;
    const update: Record<string, unknown> = { pinAttempts: attempts };

    if (attempts >= config.PIN_MAX_ATTEMPTS) {
      update.lockedUntil = new Date(Date.now() + config.PIN_LOCKOUT_MINS * 60 * 1000);
      update.pinAttempts = 0;
    }

    await prisma.user.update({ where: { id: user.id }, data: update });
    throw new AppError("Invalid credentials", 401, "INVALID_CREDENTIALS");
  }

  // Reset failed attempts on successful login
  if (user.pinAttempts > 0) {
    await prisma.user.update({
      where: { id: user.id },
      data: { pinAttempts: 0, lockedUntil: null },
    });
  }

  const payload = { userId: user.id, role: user.role };
  const accessToken = signAccessToken(payload);
  const refreshToken = signRefreshToken(payload);

  // Store refresh token in DB
  const refreshTokenHash = randomBytes(32).toString("hex");
  await prisma.refreshToken.create({
    data: {
      userId: user.id,
      token: refreshToken,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
    },
  });

  return {
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      name: user.name,
      phone: user.phone,
      role: user.role,
      designation: user.designation,
      profilePhoto: user.profilePhoto,
    },
  };
}

export async function refreshTokens(refreshToken: string) {
  // Verify JWT signature
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw new AppError("Invalid refresh token", 401, "TOKEN_INVALID");
  }

  // Check token exists in DB and is not revoked
  const storedToken = await prisma.refreshToken.findUnique({
    where: { token: refreshToken },
  });

  if (!storedToken || storedToken.revokedAt || storedToken.expiresAt < new Date()) {
    throw new AppError("Invalid refresh token", 401, "TOKEN_INVALID");
  }

  // Revoke old token
  await prisma.refreshToken.update({
    where: { id: storedToken.id },
    data: { revokedAt: new Date() },
  });

  // Issue new tokens
  const newPayload = { userId: payload.userId, role: payload.role };
  const newAccessToken = signAccessToken(newPayload);
  const newRefreshToken = signRefreshToken(newPayload);

  await prisma.refreshToken.create({
    data: {
      userId: payload.userId,
      token: newRefreshToken,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return { accessToken: newAccessToken, refreshToken: newRefreshToken };
}

export async function logout(refreshToken: string) {
  const storedToken = await prisma.refreshToken.findUnique({
    where: { token: refreshToken },
  });

  if (storedToken && !storedToken.revokedAt) {
    await prisma.refreshToken.update({
      where: { id: storedToken.id },
      data: { revokedAt: new Date() },
    });
  }
}

export async function revokeAllUserTokens(userId: string) {
  await prisma.refreshToken.updateMany({
    where: { userId, revokedAt: null },
    data: { revokedAt: new Date() },
  });
}

// Simple error class with code
export class AppError extends Error {
  statusCode: number;
  code: string;

  constructor(message: string, statusCode: number, code: string) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
  }
}
