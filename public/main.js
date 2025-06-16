const form = document.getElementById("loginForm");
const emailInput = document.getElementById("email");
const passwordInput = document.getElementById("password");
const emailError = document.getElementById("emailError");
const passwordError = document.getElementById("passwordError");
const successMessage = document.getElementById("successMessage");

form.addEventListener("submit", async (e) => {
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
    try {
      const res = await fetch("http://localhost:3000/send", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password })
      });

      if (res.ok) {
        successMessage.textContent = "Login successful!";
        form.reset();
      } else {
        successMessage.textContent = "Server error. Try again.";
      }
    } catch (err) {
      console.error("Error:", err);
      successMessage.textContent = "Network error.";
    }
  }
});