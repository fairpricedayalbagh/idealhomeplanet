// Minimal JS for the landing page
const btn = document.getElementById("download-btn");

btn?.addEventListener("click", (e) => {
  // If APK file doesn't exist yet, show a message
  const href = (e.currentTarget as HTMLAnchorElement).href;
  if (!href || href.includes("undefined")) {
    e.preventDefault();
    alert("APK is not available yet. Check back soon!");
  }
});
