const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkDate() {
  const user = await prisma.user.findUnique({ where: { phone: "7060704952" } });
  console.log("Created at:", user.createdAt);
  console.log("Updated at:", user.updatedAt);
}
checkDate().finally(() => prisma.$disconnect());
