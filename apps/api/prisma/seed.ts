import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  // Create default store config
  await prisma.storeConfig.upsert({
    where: { id: "default" },
    update: {},
    create: {
      id: "default",
      storeName: "Ideal Home Planet",
    },
  });

  // Create default admin user (PIN: 1234)
  const hashedPin = await bcrypt.hash("1234", 10);

  await prisma.user.upsert({
    where: { phone: "9999999999" },
    update: {},
    create: {
      name: "Admin",
      phone: "9999999999",
      pin: hashedPin,
      role: "ADMIN",
      designation: "Store Owner",
    },
  });

  // Create test employee (PIN: 1111)
  const empPin = await bcrypt.hash("1111", 10);

  await prisma.user.upsert({
    where: { phone: "8888888888" },
    update: {},
    create: {
      name: "Rohit Employee",
      phone: "8888888888",
      pin: empPin,
      role: "EMPLOYEE",
      designation: "Floor Staff",
      salaryType: "MONTHLY",
      monthlySalary: 25000,
      shiftStart: "09:00",
      shiftEnd: "18:00",
      graceMins: 15,
      weeklyOffDays: [0],
    },
  });

  console.log("Seed complete: StoreConfig + Admin + Employee created");
  console.log("Admin login    → phone: 9999999999, PIN: 1234");
  console.log("Employee login → phone: 8888888888, PIN: 1111");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
