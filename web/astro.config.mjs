// @ts-check
import { defineConfig } from 'astro/config';

// XyStudio AI — versi web.
// Semua halaman statis (SSG); pemanggilan Groq dilakukan dari browser
// karena api.groq.com mengizinkan CORS (access-control-allow-origin: *).
//
// Catatan deploy: kalau mau taruh di GitHub Pages (https://user.github.io/repo),
// tambahkan: base: '/groq-studio',
export default defineConfig({
  outDir: 'dist',
  server: {
    host: '0.0.0.0',
    port: 4321,
  },
});
