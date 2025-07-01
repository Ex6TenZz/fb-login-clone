import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  base: '/', // абсолютный путь — важно!
  publicDir: 'public',
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: path.resolve(__dirname, 'public/index.html')
    }
  },
  server: {
    host: '0.0.0.0',
    port: 5173
  },
  preview: {
    host: '0.0.0.0',
    port: 4173,
    allowedHosts: ['onclick-1u7s.onrender.com']
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
