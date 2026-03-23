const bcrypt = require('bcryptjs');

async function crack() {
  const hash = "$2a$10$GR6HxjNoXxVnEMtGA6nUca.yaprTcokVmMYIP2/W35xX4M";
  console.log("Starting cracking...");
  for (let i = 0; i <= 9999; i++) {
    const pin = i.toString().padStart(4, "0");
    if (await bcrypt.compare(pin, hash)) {
      console.log("FOUND PIN:", pin);
      return;
    }
  }
  console.log("NOT FOUND IN 0000-9999");
}
crack();
