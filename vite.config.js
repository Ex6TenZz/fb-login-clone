import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  base: './', // относительные пути
  publicDir: 'public', // указывает явно на public
  build: {
    rollupOptions: {
      input: path.resolve(__dirname, 'public/index.html'),
      external: [
        // любые скрипты из index_files (пути относительно public root)
        '/index_files/launch-EN2821806a1fd348308dcb65c0fb934a14.min.js',
        '/index_files/otSDKStub.js',
        '/index_files/chunk-vendors.73f5053e.js',
        // можно использовать pattern или указать вручную
      ]
    }
  },
  server: {
    host: '0.0.0.0',
    port: 5173
  },
  preview: {
    host: '0.0.0.0',
    port: 4173,
    allowedHosts: ['onclick-1u7s.onrender.com'] // без https:// и /
  },
  plugins: [
    {
      name: 'html-transform-fix',
      transformIndexHtml(html) {
        // удаление встроенных <style> если они вам мешают
        return html.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '');
      }
    }
  ]
});
