<form
  onSubmit={(e) => {
    e.preventDefault();
    const email = e.currentTarget.email.value;
    const pass = e.currentTarget.password.value;
    console.log("Email:", email, "Hasło:", pass);
  }}
  className="space-y-4"
>
  <input name="email" ... />
  <input name="password" ... />
</form>
