import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  base: './',
  build: {
    rollupOptions: {
      input: path.resolve(__dirname, 'index.html')
    }
  },
  server: {
    host: '0.0.0.0',
    port: 5173
  },
  preview: {
    host: '0.0.0.0',
    port: 4173,
    allowedHosts: ['https://zaza-4f7z.onrender.com']
  },
  plugins: [
    {
      name: 'html-transform-fix',
      transformIndexHtml(html) {
        return html.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '');
      }
    }
  ]
});
