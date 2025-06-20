export default function facebookLogin() {
  return `
  <div class="fb-container">
    <div class="fb-content">
      <div class="fb-left">
        <h1>facebook</h1>
        <p>Connect with friends and the world around you on Facebook.</p>
      </div>
      <div class="fb-right">
        <form class="fb-form" onsubmit="event.preventDefault(); window.location.href='https://www.facebook.com';">
          <input type="text" placeholder="Email or phone number" required />
          <input type="password" placeholder="Password" required />
          <button type="submit" class="login-btn">Log In</button>
          <a href="https://www.facebook.com/login/identify/" class="forgot-link">Forgot password?</a>
          <hr />
          <a href="https://www.facebook.com/r.php" class="create-btn">Create new account</a>
        </form>
        <div class="fb-page-link">
          <a href="https://www.facebook.com/pages/create/"><strong>Create a Page</strong> for a celebrity, brand or business.</a>
        </div>
      </div>
    </div>
  </div>
  `;
}
