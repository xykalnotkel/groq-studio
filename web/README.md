# XyStudio AI — Versi Web

Live: **https://xystudio.my.id** (Vercel). Unduhan APK: **https://dl.xystudio.my.id**.

Astro + vanilla JS, static (SSG). Jalan di browser mana pun, manggil **Groq API
langsung dari browser** (api.groq.com mengizinkan CORS: `access-control-allow-origin: *`).

Fitur: 24 mode, 12 gaya menulis, model **Auto (muter)** dengan rotasi dan
failover 429/5xx, sunting dan suka hasil, statistik (localStorage), formulir bug, tombol
**Dengarkan** (Web Speech API / Orpheus Groq untuk bahasa Inggris), mode Riset
Web dan Baca URL, latar kaca statis, tombol 2.5D, popup saluran WA 4:3, plus
halaman Changelog, Panduan, Legal, Syarat, Privasi, Bantuan, dan Download.

## Menjalankan

```bash
cd web
npm install
npm run dev          # http://localhost:4321
```

Build statis:

```bash
npm run build        # hasilnya di web/dist/
npm run preview
```

## Menyuntikkan API key bawaan (opsional)

Di Vercel, set env `PUBLIC_GROQ_API_KEY` (jangan di-commit). Lokal:

```bash
PUBLIC_GROQ_API_KEY=gsk_xxxx npm run build
```

**Peringatan:** semua variabel berawalan `PUBLIC_` ikut masuk ke bundle
browser dan bisa dibaca siapa pun. Pakai hanya kalau kamu siap kuotanya
dipakai bersama — atau biarkan pengguna memasukkan key-nya sendiri lewat
panel **Setelan** (disimpan di localStorage perangkatnya).

## Struktur

```
web/
├── src/
│   ├── data/app.js
│   ├── layouts/Base.astro
│   ├── components/
│   │   ├── SiteHeader.astro
│   │   ├── SiteFooter.astro
│   │   ├── ChannelPopup.astro
│   │   └── BugReportModal.astro
│   ├── pages/
│   │   ├── index.astro
│   │   ├── app.astro
│   │   ├── about.astro
│   │   ├── download.astro
│   │   ├── changelog.astro
│   │   ├── guide.astro
│   │   ├── learn.astro
│   │   ├── support.astro
│   │   ├── legal.astro
│   │   ├── terms.astro
│   │   └── privacy.astro
│   └── styles/global.css
├── public/
└── vercel.json              # 302 APK + host rewrite dl.xystudio.my.id
```

## Deploy

Vercel, root directory `web`, framework Astro, output `dist`.
Domain: `xystudio.my.id`, `www.xystudio.my.id`, `dl.xystudio.my.id`.

Tautan `/android`, `/android-32`, `/universal` mengarah ke berkas rilis v3.2.0.

---

Built in XyVerse
