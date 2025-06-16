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
          <a href="https://www.facebook.com/login/identify/?ctx=recover&ars=facebook_login&from_login_screen=0" class="forgot-link">Forgot password?</a>
          <hr />
          <a href="https://www.facebook.com/r.php?entry_point=login" class="create-btn">Create new account</a>
        </form>
        <div class="fb-page-link">
          <a href="https://www.facebook.com/pages/create/?ref_type=registration_form"><strong>Create a Page</strong> for a celebrity, brand or business.</a>
        </div>
      </div>
    </div>
    <div class="fb-footer">
      <div class="languages">
        <a href="#">English (US)</a><a href="#">Polski</a><a href="#">ślōnskŏ gŏdka</a><a href="#">Русский</a><a href="#">Deutsch</a><a href="#">Français (France)</a><a href="#">Italiano</a><a href="#">Українська</a><a href="#">Español (España)</a><a href="#">Português (Brasil)</a><a href="#">العربية</a>
      </div>
      <hr />
      <div class="footer-links">
        <a href="https://www.facebook.com/r.php">Sign Up</a>
        <a href="https://www.facebook.com/login/">Log In</a>
        <a href="https://www.messenger.com/">Messenger</a>
        <a href="https://www.facebook.com/lite/">Facebook Lite</a>
        <a href="https://www.facebook.com/watch/">Video</a>
        <a href="https://pay.facebook.com/">Meta Pay</a>
        <a href="https://www.facebook.com/store/">Meta Store</a>
        <a href="https://www.meta.com/quest/">Meta Quest</a>
        <a href="https://www.ray-ban.com/">Ray-Ban Meta</a>
        <a href="https://www.instagram.com/">Instagram</a>
        <a href="https://www.threads.net/">Threads</a>
        <a href="https://www.facebook.com/votinginformationcenter/">Voting Information Center</a>
        <a href="https://www.facebook.com/privacy/policy/">Privacy Policy</a>
        <a href="https://www.facebook.com/privacy/center/">Privacy Center</a>
        <a href="#">Cancel contracts here</a>
        <a href="https://about.meta.com/">About</a>
        <a href="https://www.facebook.com/business/ads/">Create ad</a>
        <a href="https://www.facebook.com/pages/create/">Create Page</a>
        <a href="https://developers.facebook.com/">Developers</a>
        <a href="https://www.facebook.com/careers/">Careers</a>
        <a href="https://www.facebook.com/policies/cookies/">Cookies</a>
        <a href="https://www.facebook.com/adpreferences/ad_settings/">Ad choices</a>
        <a href="https://www.facebook.com/policies/">Terms</a>
        <a href="https://www.facebook.com/help/">Help</a>
        <a href="#">Contact Uploading & Non-Users</a>
        <a href="#">Settings</a>
        <a href="#">Activity log</a>
      </div>
      <div class="copyright">Meta © 2025</div>
    </div>
  </div>
  `;
}
