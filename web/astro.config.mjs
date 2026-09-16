// @ts-check
import { defineConfig } from 'astro/config';

// XyStudio AI — versi web.
// Semua halaman statis (SSG); pemanggilan Groq dilakukan dari browser
// karena api.groq.com mengizinkan CORS (access-control-allow-origin: *).
export default defineConfig({
  site: 'https://xystudio.my.id',
  outDir: 'dist',
  server: {
    host: '0.0.0.0',
    port: 4321,
  },
});
