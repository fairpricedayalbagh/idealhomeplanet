const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function testPin() {
  const user = await prisma.user.findUnique({ where: { phone: "7060704952" } });
  console.log("Hashed PIN:", user.pin);
  const match = await bcrypt.compare("1234", user.pin);
  console.log("PIN Matches '1234':", match);
}
testPin().finally(() => prisma.$disconnect());
