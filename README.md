# XyStudio AI

Aplikasi Android (Flutter) + web untuk bikin **judul, artikel, caption, bio sosmed,
script video, prompt gambar & video, riset web, ringkasan URL**, dan banyak lagi —
semuanya ditenagai **Groq API** (GPT-OSS 120B/20B, Qwen3.8, Allam 2).

**Repo:** <https://github.com/xykalnotkel/groq-studio> ·
**CI:** setiap push ke `main` otomatis menjalankan format-check → analyze → test → build APK + AAB. Situs web di-deploy Vercel.

> Ada dua versi: **aplikasi Android** (folder ini) dan **versi web** (folder
> [`web/`](web/README.md) — Astro) di **https://xystudio.my.id**.
> Unduhan APK resmi: **https://dl.xystudio.my.id**.

> Preview tampilan (statis): buka `preview/ui_preview.html` di browser.

Cukup tulis satu kalimat tentang idemu, pilih dari 24 mode, tekan tombol. Hasilnya
muncul dalam hitungan detik di permukaan morphing — bisa langsung
**disunting**, **disukai**, **didengarkan** (TTS), disalin, dibagikan, dan
tersimpan otomatis di riwayat.

---

## Fitur

| Fitur | Keterangan |
|---|---|
| 24 mode generate | Judul, Deskripsi, Artikel, Penjelasan Aplikasi, Play Store, Caption & Hashtag, **Bio Sosmed/Akun Aplikasi**, Ide Nama, Catatan Rilis, Copy Iklan, Email, Brainstorming, Script Video, **Prompt Gambar (Midjourney/Flux/SDXL/DALL-E + parameter & negative prompt)**, **Prompt Video (Sora/Veo/Runway/Kling)**, Kalender Konten, Terjemah & Parafrase, Deskripsi Produk, Thread X, Riset Keyword & SEO, **Riset Web (fetch sumber sendiri)**, **Baca & Ringkas URL**, Balas Chat Pembeli, Prompt Bebas |
| Model Auto (muter) | Rotasi model tiap generate + **pindah otomatis** saat 429/5xx/error; badge "dijawab oleh model" di setiap hasil; pilihan manual tetap ada |
| Daftar model live | Diambil dari `GET /models`, filter otomatis: whisper/orpheus/guard/safeguard/compound tidak muncul |
| 12 gaya menulis | Natural, Profesional, Padat & Tajam, Bercerita, Elegan, Santai, Persuasif, Informatif, Puitis, Lucu, Formal, Inspiratif — **nol emoji**: dilarang di prompt & disaring di kode |
| Sunting & Suka hasil | Hasil bisa diedit langsung di aplikasi (tersimpan ke riwayat) dan diberi suka/batal suka |
| Mode mengambang | Gelembung overlay (izin **Tampilkan di atas aplikasi lain**): generate 24 mode di atas aplikasi lain, geser posisi, ukuran K/S/B atau tarik sudut. PiP opsional |
| FAQ | Halaman FAQ di situs: API key, ukuran APK, overlay, error |
| Widget beranda | Pintasan 4 mode (Judul, Caption, Artikel, Ide) yang membuka aplikasi langsung ke mode tersebut |
| Ikon adaptif | Glyph XyVerse tanpa background (transparan) |
| Laporan bug | Formulir dalam aplikasi (perangkat, versi, mode, cerita) → terkirim rapi via WhatsApp |
| Dengarkan (TTS) | Tombol play/pause/stop + slider nada & kecepatan. Bahasa Indonesia memakai suara perangkat (flutter_tts); keluaran bahasa Inggris memakai **Groq Orpheus** |
| Statistik | Total generate, kata, karakter, mode favorit, streak harian, grafik 7 hari, tombol reset |
| Popup komunitas | Ajakan gabung **Saluran WA XyVerse**: header ilustrasi kaca statis 4:3, tombol X, centang "Jangan tampilkan lagi", tombol **Laporkan bug** (formulir → WA 6283116632566), credit **Built in XyVerse** dengan logo resmi |
| Streaming real-time | Hasil muncul per kata, ada tombol **Hentikan** |
| Bahasa bisa diganti | Indonesia, English, Melayu, Jepang, Mandarin, Arab, Spanyol |
| Kreativitas & penalaran | Slider temperature 0.0 – 1.5; reasoning effort GPT-OSS (low/medium/high) |
| Riwayat | Semua hasil tersimpan di HP, bisa dicari, difavoritkan, dihapus (geser kartu) |
| Salin & bagikan | Satu ketuk untuk copy atau share ke WA/IG/dll |
| Tema | Gelap / Terang / ikut sistem, font Plus Jakarta Sans |
| Tanpa backend | Aplikasi ngobrol langsung ke `api.groq.com` |

## UI/UX: morphing surface

v3.2 mengembalikan gerak morphing (atas permintaan) dan **mengganti fade halaman
dengan geser**. Typewriter tetap dimatikan — itu yang bikin layar abu waktu generate.

- **Latar blob morphing** — radial gradient yang bentuknya bernapas pelan, tanpa `saveLayer` (itu yang membuat Impeller menampilkan layar abu).
- **Tombol morph** — idle lebar penuh, loading jadi pil, streaming jadi tombol stop bundar.
- **Loading shimmer** — kerangka garis yang bernapas.
- **Transisi halaman** — geser dari kanan, bukan fade (`lib/theme/motion.dart`).
- **Hasil streaming** — teks polos selama menulis, markdown rapi setelah selesai (mencegah layar abu).
- Material 3, sudut membulat konsisten, tipografi Plus Jakarta Sans.

---

## Unduh APK siap pasang

Rilis terbaru: <https://github.com/xykalnotkel/groq-studio/releases/latest>

| File | Untuk |
|---|---|
| `XyStudio-3.2.2-arm64-v8a.apk` | **Pilihan utama** — hampir semua HP Android modern |
| `XyStudio-3.2.2-armeabi-v7a.apk` | HP Android lama / 32-bit |
| `XyStudio-3.2.2-universal.apk` | Semua arsitektur (ukuran paling besar) |
| `XyStudio-3.2.2.aab` | Siap untuk Play Store nanti |

Unduh resmi: **https://dl.xystudio.my.id** (bukan tautan github.com).
Mulai 3.2.2 APK ditandatangani **keystore resmi XyVerse** (bukan debug) dan
kode Java/Kotlin di-minify R8. Android tetap bisa memperingatkan "sumber tidak
dikenal" karena aplikasi belum di Play Store — itu pengingat sideload, bukan
vonis malware.

Belum di Play Store karena biaya daftar developer (~25 USD sekali) belum ada.

Kalau HP sudah terpasang 3.2.1 atau lebih lama, **uninstall dulu** lalu pasang
3.2.2 (tanda tangan berubah).

## Ambil API key Groq (gratis)

1. Buka <https://console.groq.com/keys>
2. Login (Google/GitHub), lalu **Create API Key**
3. Salin key-nya (awalan `gsk_...`)
4. Di aplikasi: buka tab **Setelan** → tempel di kolom **API key Groq** → **Simpan**
   → tombol **Tes koneksi** untuk memastikan berhasil.

---

## Dua cara pakai API key

| Cara | Untuk siapa | Cara pasang |
|---|---|---|
| **Ketik manual di aplikasi** | Pemakaian pribadi; key milik sendiri | Tab **Setelan** → tempel key → Simpan (tersimpan di perangkat) |
| **Ditanam saat build** | APK yang dibagikan ke banyak orang | `flutter build apk --release --obfuscate --split-debug-info=build/symbols --dart-define=GROQ_API_KEY=gsk_xxx` |

Untuk CI, cukup taruh key di secret `GROQ_API_KEY` pada repo — workflow akan
menyuntikkannya otomatis lewat `--dart-define`.

**Keamanan:** apa pun yang di-`--dart-define` **masih bisa diekstrak** dari
APK oleh orang yang tahu caranya (walau jauh lebih sulit berkat
`--obfuscate`). Jadi:
- Pakai key dengan limit/kuota terpisah untuk APK yang disebar luas.
- Jangan pernah menaruh key mentah di dalam source code yang di-commit.
- Opsi paling aman: biarkan setiap pengguna memakai key-nya sendiri.

## Cara menjalankan di laptop

```bash
# butuh Flutter 3.27+ (project ini dibuat dengan 3.47.4)
flutter pub get
flutter run
```

Atau langsung inject key saat menjalankan (tidak perlu mengetik di HP):

```bash
flutter run --dart-define=GROQ_API_KEY=gsk_xxxxxxxxxxxx
```

## Build APK

```bash
# APK universal
flutter build apk --release

# APK per-arsitektur (lebih kecil)
flutter build apk --release --split-per-abi

# App Bundle untuk Play Store
flutter build appbundle --release
```

Suntikkan API key supaya pengguna tidak perlu mengetik sendiri:

```bash
flutter build apk --release --dart-define=GROQ_API_KEY=gsk_xxxxxxxxxxxx
```

> Bila APK ditandatangani dengan key debug, tambahkan `--release` saat install
> di HP biasa tetap bisa; hanya Play Store yang menolak. Lihat bagian signing di bawah.

---

## Build otomatis di GitHub Actions

Workflow ada di `.github/workflows/build.yml`. Jalan otomatis saat:
- push ke `main` / `master`
- pull request
- push tag `v*` → otomatis **membuat GitHub Release** berisi APK + AAB
- tombol **Run workflow** (manual) di tab Actions

Hasil build bisa diunduh di bagian **Artifacts** pada halaman workflow run.

### Secret yang bisa diatur (Settings → Secrets → Actions)

| Secret | Wajib? | Isi |
|---|---|---|
| `GROQ_API_KEY` | opsional | `gsk_...` — disuntikkan ke APK lewat `--dart-define`. Kalau kosong, pengguna mengisi sendiri di aplikasi |
| `KEYSTORE_BASE64` | wajib untuk tag `v*` | `base64 -w0 namafile.jks` |
| `KEYSTORE_PASSWORD` | wajib untuk tag `v*` | password keystore |
| `KEY_ALIAS` | wajib untuk tag `v*` | alias key (`xystudio`) |
| `KEY_PASSWORD` | wajib untuk tag `v*` | password key |

Tanpa secret keystore, push ke `main` masih membangun APK debug-signed.
Tag rilis `v*` **gagal** jika keystore belum diisi.

Membuat keystore:

```bash
keytool -genkey -v -keystore ~/groqstudio.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias groqstudio
base64 -w0 ~/groqstudio.jks > keystore.txt   # isi keystore.txt → secret KEYSTORE_BASE64
```

### Merilis versi baru

```bash
# 1. naikkan version di pubspec.yaml, misal 3.1.0+5
git add . && git commit -m "rilis 3.1.0"
git tag v3.1.0
git push origin main --tags
# 2. GitHub Actions akan membuat Release berisi APK-nya
```

---

## Struktur folder

```
lib/
├── main.dart               # bootstrap + penanganan error
├── app.dart                # MaterialApp, tema, mode gelap/terang
├── core/
│   ├── constants.dart      # metadata aplikasi & daftar model bawaan
│   ├── controller.dart     # state: auto-rotasi model, generate, statistik
│   ├── groq_client.dart    # HTTP client Groq (chat + TTS Orpheus + /models)
│   ├── prompt_builder.dart # penyusun system/user prompt per mode
│   ├── speech.dart         # tombol Dengarkan: flutter_tts + Orpheus
│   ├── stats.dart          # statistik pemakaian (streak, grafik 7 hari)
│   ├── storage.dart        # SharedPreferences
│   ├── text_utils.dart     # pembersih emoji, HTML → teks
│   └── web_research.dart   # mode Riset Web & Baca URL (fetch sumber)
├── models/                 # settings, generation_mode, history_item
├── screens/                # home, history (+detail), settings, root_shell
├── widgets/                # mode selector, markdown lite, result view, dll
└── theme/app_theme.dart    # warna, gradien, tipografi
```

### Alur singkat

```
Pengguna pilih mode + menulis brief
        ↓
AppController.generate()
        ↓
PromptBuilder (system + user prompt sesuai mode, bahasa, gaya, panjang)
        ↓
GroqClient.stream()  →  POST https://api.groq.com/openai/v1/chat/completions
        ↓
potongan teks (delta) → UI diperbarui langsung
        ↓
selesai → otomatis tersimpan ke Riwayat
```

---

## 🔒 Catatan keamanan

- API key disimpan di perangkat (`SharedPreferences`) dan dikirim **langsung** ke
  `api.groq.com`. Tidak ada server perantara.
- Untuk APK yang dibagikan ke banyak orang, **jangan** menyuntikkan key pribadi
  kecuali kamu siap kuotanya dipakai bersama. Atau buat key khusus dengan limit.
- File `android/key.properties` dan `*.jks` sudah masuk `.gitignore`.

---

## 🛠 Troubleshooting

| Gejala | Solusi |
|---|---|
| "API key tidak valid" | Salin ulang dari console.groq.com, pastikan tidak ada spasi |
| "Kuota/limit Groq sedang penuh" | Ganti ke model kecil (Llama 3.1 8B Instant) atau tunggu sebentar |
| Hasil kosong / putus di tengah | Matikan **streaming** di Setelan, atau pilih model lain |
| Tidak ada koneksi | Pastikan HP online; aplikasi butuh internet untuk menghubungi Groq |

---

## 🌐 Versi Web (Astro)

```bash
cd web
npm install
npm run dev      # http://localhost:4321
```

Situs: <https://xystudio.my.id> — `/` landing · `/app` generator · `/download` APK · `/about` dan halaman legal.
Detail lengkap ada di [`web/README.md`](web/README.md).

## 🏪 Materi Play Store

Semua ada di folder `store/`: `store_listing.md` (judul, deskripsi singkat,
deskripsi lengkap, keyword, checklist submit), `feature_graphic.png` (1024×500),
dan `screenshots/` (5 screenshot 1080×1920).

Screenshot-nya **bukan editan** — dirender langsung dari UI aplikasi:

```bash
flutter test --tags=screenshot --update-goldens   # → test/goldens/*.png
```

---

Dibuat dengan Flutter 💜 — bebas dimodifikasi.
