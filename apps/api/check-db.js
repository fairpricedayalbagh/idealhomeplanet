const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkUser() {
  const user = await prisma.user.findUnique({ where: { phone: "7060704952" } });
  console.log("User:", user);
}
checkUser().finally(() => prisma.$disconnect());
