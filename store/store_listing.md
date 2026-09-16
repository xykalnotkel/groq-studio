# Play Store Listing — Groq Studio

Salin-tempel materi di bawah ini ke Google Play Console.
Semua teks sudah disesuaikan dengan batas karakter Play Store.

---

## 🏷️ Nama aplikasi (30 karakter)

```
Groq Studio: AI Writer
```
> Alternatif: `Groq Studio — AI Nulis` · `Groq Studio: Judul & Artikel`

## 📝 Deskripsi singkat (80 karakter)

```
Bikin judul, artikel, caption & deskripsi dalam hitungan detik. Gratis!
```
> Alternatif: `Asisten nulis AI: judul, artikel, caption, ide. Cepat & gratis.`

## 📄 Deskripsi lengkap (maks. 4000 karakter)

```
Punya ide tapi malas menulis? Serahkan ke Groq Studio.

Groq Studio adalah asisten menulis bertenaga AI yang membantu kamu membuat
judul, deskripsi, artikel, caption media sosial, penjelasan aplikasi, dan
banyak lagi — cukup dari satu kalimat singkat. Hasilnya muncul kata demi kata,
langsung bisa disalin dan dipakai.

⚡ CEPAT
Didukung Groq, salah satu layanan AI tercepat saat ini. Hasil mulai muncul
dalam hitungan detik, bukan menit.

🧠 15 MODE SIAP PAKAI
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
• Prompt gambar untuk Midjourney/SDXL/Flux
• Kalender konten 7–30 hari
• Prompt bebas

🎛️ HASIL BISA DIATUR
Pilih bahasa (Indonesia, Inggris, dan lainnya), gaya penulisan (profesional,
santai, persuasif, lucu, formal, inspiratif), panjang hasil, dan tingkat
kreativitas. Pilih juga model AI yang dipakai — daftar model diambil langsung
dari akun Groq kamu.

✨ TAMPILAN MODERN
UI bergaya morphing: latar yang bergerak halus, tombol yang berubah bentuk
menjadi tombol berhenti saat teks ditulis, dan transisi antar halaman yang
terasa menyatu. Tersedia tema gelap dan terang.

📚 RIWAYAT TERSIMPAN
Setiap hasil otomatis tersimpan di perangkat. Bisa dicari, ditandai favorit,
disalin, atau dibagikan ke WhatsApp, Instagram, dan aplikasi lain.

🔒 PRIVASI
API key kamu disimpan hanya di perangkat dan dikirim langsung ke api.groq.com.
Tidak ada server perantara, tidak ada data yang dikumpulkan pengembang.

CARA PAKAI
1. Ambil API key gratis di console.groq.com/keys
2. Buka tab Setelan, tempel key-nya, lalu Tes Koneksi
3. Kembali ke tab Buat: pilih mode, tulis idemu, tekan tombol
4. Salin atau bagikan hasilnya. Selesai.

Groq Studio cocok untuk kreator konten, pelaku UMKM, developer yang ingin
menulis deskripsi aplikasinya, blogger, mahasiswa, dan siapa pun yang perlu
menulis lebih cepat.

Unduh sekarang dan mulai menulis tanpa hambatan.
```

## 🔑 Kata kunci (kolom keywords Play Console)

```
ai writer,ai writing,artikel,ai,judul,caption,copywriting,generator,konten,
chatbot,llama,groq,penulis,deskripsi,ide,script,prompt,gambar,umkm,creator
```

## 🆕 What's New (catatan rilis)

**v1.1.0**
- 3 mode baru: Script Video, Prompt Gambar, Kalender Konten
- Font Plus Jakarta Sans dibundel → tampilan konsisten walau offline
- Perbaikan tata letak header & kartu mode di layar kecil
- Screenshot promosi kini dihasilkan langsung dari UI aplikasi

**v1.0.0**
- Rilis perdana: 12 mode generate, streaming real-time, riwayat lokal,
  UI morphing, tema gelap/terang

## 🎨 Aset grafis (ada di folder ini)

| File | Ukuran | Kegunaan |
|---|---|---|
| `feature_graphic.png` | 1024×500 | **Wajib** — banner utama Play Store |
| `screenshots/01_home.png` | 1080×1920 | Tangkapan layar utama |
| `screenshots/02_hasil.png` | 1080×1920 | Contoh artikel yang dihasilkan |
| `screenshots/03_riwayat.png` | 1080×1920 | Halaman riwayat |
| `screenshots/04_setelan.png` | 1080×1920 | Pengaturan & API key |
| `screenshots/05_mode.png` | 1080×1920 | Daftar mode lengkap |

Screenshot dihasilkan otomatis dari UI asli aplikasi (Flutter golden test):

```bash
flutter test --tags=screenshot --update-goldens
```

## 📋 Checklist sebelum submit

- [ ] Kategori: **Productivity** (alternatif: Tools)
- [ ] Content rating: isi kuesioner → kemungkinan **Everyone** (tidak ada konten sensitif; hasil AI tidak difilter, sebaiknya cantumkan di deskripsi)
- [ ] **Data Safety**: nyatakan bahwa aplikasi mengirim teks ke api.groq.com (enkripsi in transit). Tidak ada pengumpulan data oleh pengembang.
- [ ] **Privacy policy URL** — wajib. Contoh gratis: buat halaman sederhana di GitHub Pages / Notion yang berisi: data apa yang dikirim (teks brief ke Groq), tidak disimpan di server pengembang, API key hanya di perangkat, tidak ada analitik pihak ketiga.
- [ ] **Target audience**: 13+ (karena output AI)
- [ ] APK/AAB ditandatangani dengan keystore sendiri (lihat README → signing)
- [ ] Ikon aplikasi: `assets/app_icon_512.png` (sudah 512×512)
- [ ] Min. 2 screenshot (sudah ada 5) + feature graphic (sudah ada)

## 🏪 Catatan rilis ke Play Store

```bash
# 1. siapkan keystore, lalu masukkan sebagai secret di GitHub
keytool -genkey -v -keystore ~/groqstudio.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias groqstudio
base64 -w0 ~/groqstudio.jks > keystore.txt

# 2. naikkan versi di pubspec.yaml lalu tag
git tag v1.1.0 && git push origin main --tags

# 3. unduh AAB dari GitHub Release, unggah ke Play Console
```
