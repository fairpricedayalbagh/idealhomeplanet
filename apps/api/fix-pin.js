const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function fix() {
  const hash = await bcrypt.hash("1234", 10);
  await prisma.user.update({
    where: { phone: "7060704952" },
    data: { pin: hash, pinAttempts: 0, lockedUntil: null }
  });
  console.log("PIN reset to 1234");
}
fix().catch(console.error).finally(() => prisma.$disconnect());
