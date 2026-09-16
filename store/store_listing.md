# Play Store Listing — XyStudio AI

Status: BELUM dikirim ke Google Play.
Alasan: biaya daftar developer (~25 USD sekali) belum ada. Bukan karena
aplikasi malware/virus. Materi di bawah siap disalin nanti.

Salin-tempel materi di bawah ini ke Google Play Console.
Semua teks sudah disesuaikan dengan batas karakter Play Store.

---

## 🏷️ Nama aplikasi (30 karakter)

```
XyStudio AI
```
> Alternatif: `XyStudio AI: Penulis` · `XyStudio AI Writer`

## 📝 Deskripsi singkat (80 karakter)

```
Bikin judul, artikel, caption & script video dalam hitungan detik. Gratis!
```
> Alternatif: `Asisten nulis AI: judul, artikel, caption, script. Cepat & gratis.`

## 📄 Deskripsi lengkap (maks. 4000 karakter)

```
Punya ide tapi malas menulis? Serahkan ke XyStudio AI.

XyStudio AI adalah studio menulis bertenaga AI yang membantu kamu membuat
judul, artikel, caption, naskah video, prompt gambar, deskripsi produk, dan
banyak lagi — cukup dari satu kalimat. Hasilnya muncul kata demi kata,
langsung bisa disalin dan dipakai.

⚡ CEPAT
Didukung Groq, salah satu layanan AI tercepat saat ini. Hasil mulai muncul
dalam hitungan detik, bukan menit.

🧠 20 MODE SIAP PAKAI
• Judul & headline yang bikin orang klik
• Deskripsi singkat yang menjual
• Artikel lengkap + outline + FAQ
• Penjelasan aplikasi ("aplikasi ini apa?")
• Deskripsi Play Store & App Store
• Caption + hashtag Instagram/TikTok
• Ide nama brand & produk
• Catatan rilis (changelog)
• Copy iklan (hook, body, CTA)
• Email & pengumuman
• Brainstorming ide
• Script video YouTube/TikTok/Reels
• Prompt gambar Midjourney/SDXL/Flux
• Kalender konten 7–30 hari
• Terjemahan & parafrase
• Deskripsi produk toko online + SEO
• Thread X/Twitter
• Riset keyword & rencana SEO
• Balasan chat pembeli (CS)
• Prompt bebas

🎛️ HASIL BISA DIATUR
Pilih bahasa (Indonesia, Inggris, dan lainnya), gaya penulisan (profesional,
santai, persuasif, lucu, formal, inspiratif), panjang hasil, tingkat
kreativitas, dan model AI yang dipakai.

✨ TAMPILAN MODERN
UI bergaya morphing: latar yang bergerak halus, tombol yang menyusut jadi
tombol berhenti saat teks ditulis, dan transisi antar halaman yang menyatu.
Ada tema gelap dan terang.

📚 RIWAYAT TERSIMPAN
Setiap hasil otomatis tersimpan di perangkat. Bisa dicari, ditandai favorit,
disalin, atau dibagikan.

🔒 PRIVASI
API key kamu disimpan hanya di perangkat dan dikirim langsung ke
api.groq.com. Tidak ada server perantara, tidak ada data yang dikumpulkan.

CARA PAKAI
1. Ambil API key gratis di console.groq.com/keys
2. Buka tab Setelan, tempel key-nya, lalu Tes Koneksi
3. Kembali ke tab Buat: pilih mode, tulis idemu, tekan tombol
4. Salin atau bagikan hasilnya. Selesai.

Cocok untuk kreator konten, pelaku UMKM, developer, blogger, mahasiswa, dan
siapa pun yang ingin menulis lebih cepat.

Built in XyVerse 💜
```

## 🔑 Kata kunci

```
ai writer,ai writing,artikel,ai,judul,caption,copywriting,generator,konten,
chatbot,llama,groq,penulis,deskripsi,script,prompt,gambar,translate,seo,umkm
```

## 🆕 What's New

**v2.0.0**
- Nama & identitas baru: **XyStudio AI** (dulu Groq Studio)
- Logo baru + splash screen dengan credit Built in XyVerse
- 5 mode baru: Terjemah & Parafrase, Deskripsi Produk, Thread X, Riset Keyword & SEO, Balas Chat Pembeli
- Popup ajakan gabung Saluran WA XyVerse + tombol "Laporkan bug"
- Font Plus Jakarta Sans dibundel (tetap rapi walau offline)
- Versi web tersedia di browser

**v1.1.0**
- Mode Script Video, Prompt Gambar, Kalender Konten
- Screenshot Play Store dihasilkan langsung dari UI aplikasi

## 🎨 Aset grafis

| File | Ukuran | Kegunaan |
|---|---|---|
| `feature_graphic.png` | 1024×500 | **Wajib** — banner utama |
| `screenshots/01_home.png` | 1080×1920 | Halaman utama |
| `screenshots/02_hasil.png` | 1080×1920 | Contoh artikel dihasilkan |
| `screenshots/03_riwayat.png` | 1080×1920 | Riwayat |
| `screenshots/04_setelan.png` | 1080×1920 | Setelan & API key |
| `screenshots/05_mode.png` | 1080×1920 | Daftar mode |
| `screenshots/06_popup.png` | 1080×1920 | Popup saluran WA |

Regenerate kapan saja dari UI asli:

```bash
flutter test --tags=screenshot --update-goldens
```

## 📋 Checklist submit

- [ ] Kategori: **Productivity**
- [ ] Content rating: isi kuesioner → kemungkinan **Everyone** (beri catatan bahwa output AI tidak difilter)
- [ ] **Data Safety**: nyatakan aplikasi mengirim teks ke api.groq.com (terenkripsi). Tidak ada pengumpulan data oleh pengembang.
- [ ] **Privacy policy URL** — wajib (halaman sederhana juga boleh)
- [ ] Target audience: 13+
- [ ] APK/AAB ditandatangani keystore sendiri (lihat README)
- [ ] Ikon: `assets/app_icon_512.png`
- [ ] Min. 2 screenshot + feature graphic ✅
