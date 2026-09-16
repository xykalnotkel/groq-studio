# XyStudio AI — Versi Web

Astro + vanilla JS, static (SSG). Jalan di browser mana pun, manggil **Groq API
langsung dari browser** (api.groq.com mengizinkan CORS: `access-control-allow-origin: *`).

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

```bash
PUBLIC_GROQ_API_KEY=gsk_xxxx npm run build
```

⚠️ **Peringatan:** semua variabel berawalan `PUBLIC_` ikut masuk ke bundle
browser dan bisa dibaca siapa pun. Pakai hanya kalau kamu siap kuotanya
dipakai bersama — atau biarkan pengguna memasukkan key-nya sendiri lewat
panel **Setelan** (disimpan di localStorage perangkatnya).

## Struktur

```
web/
├── src/
│   ├── data/app.js          # konfigurasi + daftar mode (sama dgn Android)
│   ├── layouts/Base.astro   # kerangka, footer, credit, popup
│   ├── components/
│   │   └── ChannelPopup.astro  # popup saluran WA (X, centang, lapor bug)
│   ├── pages/
│   │   ├── index.astro      # landing
│   │   ├── app.astro        # generator (streaming, riwayat, setelan)
│   │   └── about.astro      # tentang + credit
│   └── styles/global.css    # morphing background & komponen
└── public/                  # logo, wa-channel.png, shots/
```

## Fitur

- 20 mode generate, identik dengan aplikasi Android
- Streaming kata demi kata (SSE) + tombol hentikan
- Bahasa / gaya / panjang / model / kreativitas
- Riwayat tersimpan di localStorage (50 entri terakhir)
- Salin hasil, buka kembali dari riwayat
- Popup saluran WA: tombol **X**, centang **Jangan tampilkan lagi**, tombol **Laporkan bug**
- Tema gelap dengan latar morphing

## Deploy

- **Vercel / Netlify**: arahkan ke folder `web/`, build `npm run build`, output `dist`
- **GitHub Pages**: tambahkan `base: '/groq-studio'` di `astro.config.mjs`

---

Built in XyVerse 💜
