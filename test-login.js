fetch("https://idealhomeplanet-api.vercel.app/api/auth/login", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ phone: "7060704952", pin: "1234" })
})
.then(res => res.text())
.then(console.log)
.catch(console.error);
