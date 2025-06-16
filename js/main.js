const form = document.getElementById("loginForm");
const emailInput = document.getElementById("email");
const passwordInput = document.getElementById("password");
const emailError = document.getElementById("emailError");
const passwordError = document.getElementById("passwordError");
const successMessage = document.getElementById("successMessage");

form.addEventListener("submit", (e) => {
  e.preventDefault();

  const email = emailInput.value.trim();
  const password = passwordInput.value;

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
    successMessage.textContent = "Login successful!";
    form.reset();
  }
});
