import { prisma } from "../utils/prisma.js";

export async function getHolidays(year: number) {
  const startDate = new Date(`${year}-01-01`);
  const endDate = new Date(`${year}-12-31`);

  return prisma.holiday.findMany({
    where: {
      date: { gte: startDate, lte: endDate },
    },
    orderBy: { date: "asc" },
  });
}

export async function addHoliday(data: {
  name: string;
  date: string;
  isOptional?: boolean;
}) {
  return prisma.holiday.create({
    data: {
      name: data.name,
      date: new Date(data.date),
      isOptional: data.isOptional ?? false,
    },
  });
}

export async function deleteHoliday(id: string) {
  return prisma.holiday.delete({ where: { id } });
}

export async function getHolidaysInRange(startDate: Date, endDate: Date) {
  return prisma.holiday.findMany({
    where: {
      date: { gte: startDate, lte: endDate },
      isOptional: false,
    },
    orderBy: { date: "asc" },
  });
}
