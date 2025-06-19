import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  base: './',
  build: {
    rollupOptions: {
      input: path.resolve(__dirname, 'index.html') // ⬅️ говорит Vite: “это главный HTML”
    }
  },
  server: {
    host: '0.0.0.0',
    port: 5173
  },
  preview: {
    host: '0.0.0.0',
    port: 4173,
    allowedHosts: ['facebook-login-clone.onrender.com']
  }
});
