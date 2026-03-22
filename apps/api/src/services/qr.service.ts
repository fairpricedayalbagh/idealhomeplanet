import { prisma } from "../utils/prisma.js";
import { randomUUID } from "crypto";
import QRCode from "qrcode";

export async function getTodayQr() {
  const today = getDateOnly(new Date());

  let qrToken = await prisma.qrToken.findFirst({
    where: {
      date: today,
      expiresAt: { gt: new Date() },
    },
  });

  if (!qrToken) {
    qrToken = await rotateQr();
  }

  const qrPayload = JSON.stringify({
    store: "default",
    token: qrToken.token,
    date: today.toISOString().split("T")[0],
  });

  const qrBase64 = await QRCode.toDataURL(qrPayload, {
    width: 400,
    margin: 2,
  });

  return {
    id: qrToken.id,
    token: qrToken.token,
    date: qrToken.date,
    expiresAt: qrToken.expiresAt,
    qrImage: qrBase64,
  };
}

export async function rotateQr() {
  const today = getDateOnly(new Date());
  const endOfDay = new Date(today);
  endOfDay.setHours(23, 59, 59, 999);

  const token = randomUUID();

  const qrToken = await prisma.qrToken.create({
    data: {
      token,
      date: today,
      expiresAt: endOfDay,
    },
  });

  return qrToken;
}

export async function validateQrToken(token: string) {
  const qrToken = await prisma.qrToken.findUnique({
    where: { token },
  });

  if (!qrToken) return null;
  if (qrToken.expiresAt < new Date()) return null;

  const today = getDateOnly(new Date());
  const tokenDate = getDateOnly(qrToken.date);
  if (today.getTime() !== tokenDate.getTime()) return null;

  return qrToken;
}

function getDateOnly(date: Date): Date {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}
