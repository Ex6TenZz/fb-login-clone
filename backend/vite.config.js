import { defineConfig } from 'vite'

export default defineConfig({
  root: '.',
  build: {
    outDir: 'dist'
  },
  preview: {
    host: '0.0.0.0',
    port: 4173,
    allowedHosts: ['fb-login-frontend.onrender.com']
  }
})
