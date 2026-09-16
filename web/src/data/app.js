// Konfigurasi bersama untuk seluruh halaman web XyStudio AI.
export const APP = {
  name: 'XyStudio AI',
  brand: 'XyVerse',
  credit: 'Built in XyVerse',
  version: '3.2.2',
  tagline: 'Tulis apa saja, jadi cepat',
  description:
    'Studio menulis AI: judul, artikel, caption, riset web, prompt video, dan 24 mode lainnya. Ditenagai Groq.',
  waChannelUrl: 'https://whatsapp.com/channel/0029VbB7nwuJZg3ym6UQ4Z1L',
  waChannelName: 'Saluran WA XyVerse',
  bugReportPhone: '6283116632566',
  bugReportUrl:
    'https://wa.me/6283116632566?text=Halo%20XyVerse!%20Saya%20mau%20lapor%20bug%20di%20XyStudio%20AI%20(web):%0A%0A%E2%80%A2%20Halaman:%0A%E2%80%A2%20Mode:%0A%E2%80%A2%20Cerita%20singkat:',
  githubUrl: 'https://github.com/xykalnotkel/groq-studio',
  keysUrl: 'https://console.groq.com/keys',
  siteUrl: 'https://xystudio.my.id',
  downloadUrl: 'https://dl.xystudio.my.id',
  apkUrl: 'https://dl.xystudio.my.id/android',
  apk32Url: 'https://dl.xystudio.my.id/android-32',
  apkUniversalUrl: 'https://dl.xystudio.my.id/universal',
  releasesUrl: 'https://dl.xystudio.my.id',
};

export const DOWNLOADS = [
  {
    id: 'android',
    href: 'https://dl.xystudio.my.id/android',
    file: 'XyStudio-3.2.0-arm64-v8a.apk',
    label: 'Android 64-bit',
    note: 'Pilihan utama. Hampir semua HP Android modern.',
    primary: true,
  },
  {
    id: 'android-32',
    href: 'https://dl.xystudio.my.id/android-32',
    file: 'XyStudio-3.2.0-armeabi-v7a.apk',
    label: 'Android 32-bit',
    note: 'HP Android lama.',
  },
  {
    id: 'universal',
    href: 'https://dl.xystudio.my.id/universal',
    file: 'XyStudio-3.2.0-universal.apk',
    label: 'Universal',
    note: 'Semua arsitektur. Ukuran paling besar.',
  },
];

export const NAV = [
  { href: '/', label: 'Beranda', id: 'home' },
  { href: '/app', label: 'Web App', id: 'app' },
  { href: '/download', label: 'Download', id: 'download' },
  { href: '/faq', label: 'FAQ', id: 'faq' },
  { href: '/about', label: 'Tentang', id: 'about' },
];

export const FOOTER = {
  product: [
    { href: '/app', label: 'Web App' },
    { href: '/download', label: 'Download APK' },
    { href: '/changelog', label: 'Changelog' },
    { href: '/guide', label: 'Panduan' },
  ],
  learn: [
    { href: '/about', label: 'Tentang' },
    { href: '/learn', label: 'Pelajari lebih lanjut' },
    { href: '/guide', label: 'Panduan' },
    { href: '/changelog', label: 'Catatan rilis' },
  ],
  support: [
    { href: '/faq', label: 'FAQ' },
    { href: '/support', label: 'Bantuan' },
    { href: '#', label: 'Laporkan bug', bug: true },
    { href: 'https://whatsapp.com/channel/0029VbB7nwuJZg3ym6UQ4Z1L', label: 'Saluran WA', ext: true },
  ],
  legal: [
    { href: '/legal', label: 'Legal' },
    { href: '/terms', label: 'Syarat penggunaan' },
    { href: '/privacy', label: 'Kebijakan privasi' },
  ],
};

// 24 mode generate — sama dengan versi Android supaya hasilnya konsisten.
// kind: 'standard' | 'webResearch' | 'urlSummary'
export const MODES = [
  {
    id: 'judul', label: 'Judul', hint: 'Opsi judul yang bikin orang klik', temp: 1.0,
    placeholder: 'Contoh: aplikasi pencatat keuangan untuk anak kos',
    instruction:
      'Buatkan 10 opsi judul/headline yang menarik dari brief di bawah.\n' +
      'Aturan: beri nomor, maksimal 12 kata per judul, variasikan gayanya ' +
      '(ada yang pakai angka, pertanyaan, kata "rahasia", dan manfaat).\n' +
      'Setelah daftar, berikan 3 rekomendasi terbaik dengan tanda "[FAVORIT]" ' +
      'di depan nomor, plus satu kalimat alasan kenapa judul itu kuat.',
  },
  {
    id: 'deskripsi', label: 'Deskripsi', hint: 'Paragraf deskripsi singkat & menjual', temp: 0.8,
    placeholder: 'Contoh: aplikasi belajar bahasa Jepang dengan flashcard',
    instruction:
      'Tulis deskripsi singkat (2 paragraf) tentang hal di brief.\n' +
      'Paragraf 1: apa itu dan untuk siapa.\n' +
      'Paragraf 2: manfaat utama yang paling terasa.\n' +
      'Akhiri dengan 5 poin ringkas "Kenapa ini menarik".',
  },
  {
    id: 'artikel', label: 'Artikel', hint: 'Artikel lengkap + outline + FAQ', temp: 0.7, max: 4096,
    placeholder: 'Contoh: cara mengatur keuangan bulanan untuk pemula',
    instruction:
      'Tulis artikel lengkap berdasarkan brief.\nStruktur wajib:\n' +
      '1. Judul utama (H1)\n2. Paragraf pembuka yang menarik\n' +
      '3. 4-6 subjudul (H2) dengan isi yang benar-benar bernilai\n' +
      '4. Kesimpulan + ajakan bertindak\n5. Bagian "FAQ" berisi 3 pertanyaan & jawaban\n' +
      '6. Baris terakhir: "Meta description:" diikuti 1 kalimat (maks 155 karakter)',
  },
  {
    id: 'penjelasan', label: 'Penjelasan Aplikasi', hint: '"Aplikasi ini apa?" siap tempel', temp: 0.7,
    placeholder: 'Contoh: saya baru saja bikin aplikasi pencatat jadwal sholat',
    instruction:
      'Jelaskan aplikasi/produk di brief dengan gaya "penjelasan aplikasi".\n' +
      'Wajib memuat bagian:\n## Apa ini — 1 paragraf penjelasan sederhana\n' +
      '## Masalah yang diselesaikan — poin-poin\n' +
      '## Fitur utama — 5 poin dengan penjelasan 1 kalimat\n' +
      '## Untuk siapa — sebutkan 3 tipe pengguna\n## Cara pakai — langkah 1-4\n' +
      '## Kenapa beda — 3 poin\nTutup dengan satu kalimat rangkuman yang mudah diingat.',
  },
  {
    id: 'store', label: 'Play Store', hint: 'Judul, deskripsi, keyword listing', temp: 0.8,
    placeholder: 'Contoh: aplikasi edit foto dengan efek film klasik',
    instruction:
      'Buatkan materi listing toko aplikasi (Google Play / App Store).\nKeluarkan:\n' +
      '1. Nama aplikasi (maks 30 karakter) + 3 alternatif\n' +
      '2. Judul/subtitle promosi (maks 80 karakter)\n' +
      '3. Deskripsi singkat (maks 80 karakter)\n' +
      '4. Deskripsi lengkap (300-500 kata) dengan struktur yang enak dibaca di HP, TANPA emoji\n' +
      '5. 5 kata kunci utama (keyword field)\n6. 3 ide kalimat "What\'s New"',
  },
  {
    id: 'caption', label: 'Caption & Hashtag', hint: 'Caption IG/TikTok + hashtag', temp: 1.0,
    placeholder: 'Contoh: promo kopi susu literan di kampus',
    instruction:
      'Buatkan materi media sosial.\nKeluarkan:\n' +
      '1. 5 opsi caption dengan gaya berbeda (cerita, lucu, pertanyaan, promo, tips) — semua tanpa emoji\n' +
      '2. Setiap caption: baris hook di awal + isi + ajakan (CTA)\n' +
      '3. 15 hashtag relevan di bagian akhir\n' +
      '4. 3 ide teks untuk gambar/story (maks 8 kata)',
  },
  {
    id: 'bio', label: 'Bio Sosmed / Akun', hint: 'Bio IG/TikTok/X & bio akun aplikasi', temp: 0.95,
    placeholder: 'Contoh: akun Instagram toko kue rumahan di Bandung, target ibu muda',
    instruction:
      'Buatkan kumpulan bio berdasarkan brief.\nKeluarkan:\n' +
      '1. **Bio Instagram** — 4 opsi, maks 150 karakter per bio\n' +
      '2. **Bio TikTok** — 3 opsi, maks 80 karakter, punchy\n' +
      '3. **Bio X/Twitter** — 3 opsi, maks 160 karakter\n' +
      '4. **Bio WhatsApp / profil akun aplikasi** — 2 opsi singkat\n' +
      '5. **Nama tampilan (display name)** — 3 opsi beserta username yang matching\n' +
      'Syarat: tanpa emoji, tetap berkarakter, cantumkan kata kunci yang relevan.',
  },
  {
    id: 'nama', label: 'Ide Nama', hint: 'Nama brand/produk + maknanya', temp: 1.1,
    placeholder: 'Contoh: aplikasi pengingat minum air berbasis AI',
    instruction:
      'Beri 15 ide nama untuk hal di brief.\n' +
      'Untuk setiap nama sebutkan: nama, 1 kalimat makna/filosofinya, ' +
      'dan kemudahan diingat (mudah/sedang/sulit).\n' +
      'Kelompokkan menjadi: pendek & modern, bermakna lokal, dan unik/nyeleneh. ' +
      'Beri tanda "[FAVORIT]" pada 3 pilihan terbaikmu.',
  },
  {
    id: 'rilis', label: 'Catatan Rilis', hint: 'Changelog / release notes rapi', temp: 0.5,
    placeholder: 'Contoh: aplikasi kasir tambah fitur scan barcode & ekspor PDF',
    instruction:
      'Tulis catatan rilis (release notes) berdasarkan brief.\nKeluarkan 3 versi:\n' +
      '1. **Versi lengkap** — pembuka hangat, daftar perubahan dikelompokkan ' +
      '(Baru / Peningkatan / Perbaikan), penutup\n' +
      '2. **Versi singkat** — 4-6 baris untuk dialog update di aplikasi\n' +
      '3. **Versi media sosial** — 2-3 kalimat santai untuk pengumuman\n' +
      'Gunakan penomoran versi contoh seperti v2.1.0.',
  },
  {
    id: 'iklan', label: 'Copy Iklan', hint: 'Hook, body, dan CTA yang menjual', temp: 0.9,
    placeholder: 'Contoh: jasa cuci sepatu premium, antar-jemput gratis',
    instruction:
      'Buat copy iklan berdasarkan brief.\nKeluarkan:\n' +
      '1. **3 hook pembuka** — kalimat pertama yang menghentikan scroll\n' +
      '2. **Body copy** — 2 versi: pendek (50 kata) dan sedang (120 kata)\n' +
      '3. **5 CTA** — ajakan bertindak yang bervariasi\n' +
      '4. **Versi iklan Meta/Instagram** — primary text, headline (maks 40 karakter), ' +
      'deskripsi (maks 30 karakter)\n' +
      '5. **Versi Google Ads** — 3 headline (maks 30 karakter) + 2 deskripsi (maks 90 karakter)\n' +
      'Tanpa klaim berlebihan yang tidak bisa dibuktikan.',
  },
  {
    id: 'email', label: 'Email & Pengumuman', hint: 'Email resmi + versi singkat WA', temp: 0.6,
    placeholder: 'Contoh: undangan rapat evaluasi program untuk tim, Kamis jam 10',
    instruction:
      'Tulis email/pengumuman berdasarkan brief.\nKeluarkan:\n' +
      '1. **Subjek email** — 3 opsi, maks 60 karakter\n' +
      '2. **Isi email lengkap** — pembuka sopan, isi jelas, penutup + ttd placeholder [Nama Kamu]\n' +
      '3. **Versi singkat** — untuk chat WhatsApp/Slack (maks 60 kata)\n' +
      '4. **Versi follow-up** — jika tidak ada balasan setelah 3 hari',
  },
  {
    id: 'ide', label: 'Brainstorming', hint: 'Daftar ide + langkah eksekusi', temp: 1.0, max: 3072,
    placeholder: 'Contoh: konten edukasi keuangan untuk fresh graduate',
    instruction:
      'Lakukan brainstorming berdasarkan brief.\nKeluarkan:\n' +
      '1. **15 ide** bernomor, masing-masing 1 kalimat kuat\n' +
      '2. **3 ide terbaik** dijabarkan: kenapa potensial, targetnya, dan cara memulainya\n' +
      '3. **Langkah eksekusi 7 hari** untuk ide terbaik\n' +
      '4. **Risiko & cara mengantisipasinya** — 3 poin\n' +
      '5. **Pertanyaan yang perlu dijawab** sebelum mulai — 5 pertanyaan',
  },
  {
    id: 'script', label: 'Script Video', hint: 'Naskah YouTube/TikTok/Reels', temp: 0.95, max: 3072,
    placeholder: 'Contoh: video 60 detik tentang cara menabung 1 juta pertama',
    instruction:
      'Buat script video berdasarkan brief.\nKeluarkan:\n' +
      '1. **Hook 3 detik pertama** — 3 opsi\n' +
      '2. **Script lengkap** dengan format: [VISUAL] baris deskripsi apa yang terlihat, ' +
      'lalu baris dialog/voice over di bawahnya\n' +
      '3. **CTA penutup** — ajakan like/follow/komentar\n' +
      '4. **Judul video** — 3 opsi + 10 hashtag\n' +
      '5. **Catatan editing** — tempo, musik, dan teks layar penting',
  },
  {
    id: 'gambar', label: 'Prompt Gambar', hint: 'Prompt Midjourney/Flux/SDXL/DALL-E', temp: 0.9,
    placeholder: 'Contoh: ilustrasi warung kopi futuristik di pinggir sawah, senja',
    engines: ['Midjourney', 'Flux', 'SDXL', 'DALL-E'],
    instruction:
      'Buat prompt gambar AI berdasarkan brief.\nKeluarkan struktur berikut:\n' +
      '1. **Prompt utama (English)** — kalimat deskriptif padat: subjek, aksi, lingkungan, ' +
      'pencahayaan, mood, komposisi, gaya, detail lensa/kamera bila relevan\n' +
      '2. **3 variasi** — beda gaya (mis. fotorealistik, ilustrasi, 3D render)\n' +
      '3. **Parameter** sesuai engine target:\n' +
      '   - Midjourney: --ar, --v, --stylize, --chaos\n' +
      '   - Flux: guidance scale, jumlah step, resolusi\n' +
      '   - SDXL/SD: CFG scale, step, sampler, resolusi, seed\n' +
      '   - DALL-E: ukuran (size), style (vivid/natural), quality\n' +
      '4. **Negative prompt** — apa yang harus dihindar (tangan rusak, wajah cacat, teks, ' +
      'watermark, dll.), versi lengkap untuk SDXL/Flux dan versi ringkas untuk yang lain\n' +
      '5. **Tips singkat** — 2-3 kalimat cara memakainya di engine tersebut\n' +
      'Prompt utama WAJIB dalam bahasa Inggris.',
  },
  {
    id: 'video-prompt', label: 'Prompt Video', hint: 'Prompt Sora / Veo / Runway / Kling', temp: 0.9,
    placeholder: 'Contoh: drone shot kota Jakarta saat hujan malam hari, sinematik',
    engines: ['Sora', 'Veo', 'Runway', 'Kling'],
    instruction:
      'Buat prompt video AI berdasarkan brief.\nKeluarkan struktur berikut:\n' +
      '1. **Prompt utama (English)** — satu paragraf padat memuat: subjek, aksi/gerakan, ' +
      'pergerakan kamera (pan, dolly, orbit, handheld), pencahayaan, mood, gaya sinematik, ' +
      'durasi yang disarankan\n' +
      '2. **3 variasi shot** — mis. wide establishing, close-up detail, dan FPV/dynamic\n' +
      '3. **Parameter sesuai engine target**:\n' +
      '   - Sora: durasi, resolusi/orientasi, gaya\n' +
      '   - Veo: aspect ratio, gaya (cinematic/documentary), durasi\n' +
      '   - Runway: Gen-3/Gen-4, durasi (5/10 detik), camera control, motion intensity\n' +
      '   - Kling: durasi, mode (standard/professional), creativity & relevance scale\n' +
      '4. **Negative prompt** — hal yang dihindari (morphing aneh, wajah rusak, teks, watermark)\n' +
      '5. **Saran loop/transisi** bila cocok untuk konten sosial\n' +
      'Prompt utama WAJIB dalam bahasa Inggris.',
  },
  {
    id: 'kalender', label: 'Kalender Konten', hint: 'Jadwal konten 7–30 hari', temp: 0.95, max: 3072,
    placeholder: 'Contoh: akun TikTok kedai kopi, target mahasiswa',
    instruction:
      'Buat kalender konten berdasarkan brief.\nKeluarkan:\n' +
      '1. **Strategi singkat** — 3 pilar konten utama\n' +
      '2. **Kalender 14 hari** dalam tabel: Hari | Format | Ide Konten | Hook pembuka | Jam tayang\n' +
      '3. **5 ide konten evergreen** yang bisa dipakai kapan saja\n' +
      '4. **3 ide serial/konten berulang** (mis. "Tip Senin")\n' +
      '5. **Metrik yang perlu dipantau** — 5 metrik',
  },
  {
    id: 'terjemah', label: 'Terjemah & Parafrase', hint: 'Terjemahan natural + 3 parafrase', temp: 0.5,
    placeholder: 'Tempel teks yang mau diterjemahkan / diparafrase di sini',
    instruction:
      'Kerjakan teks pengguna:\n' +
      '1. **Terjemahan natural** — jika teks berbahasa Indonesia, terjemahkan ke Inggris; ' +
      'jika bahasa lain, terjemahkan ke bahasa keluaran yang diminta. Hasil harus luwes.\n' +
      '2. **3 parafrase** — tulis ulang dengan gaya berbeda: lebih formal, lebih santai, lebih ringkas\n' +
      '3. **Catatan** — istilah yang sulit diterjemahkan dan alasan pemilihan katanya (maks 3 poin)',
  },
  {
    id: 'produk', label: 'Deskripsi Produk', hint: 'Judul, bullet, SEO toko online', temp: 0.8,
    placeholder: 'Contoh: tas ransel laptop anti air bahan kanvas, harga 350 ribuan',
    instruction:
      'Buat materi deskripsi produk untuk toko online.\nKeluarkan:\n' +
      '1. **Judul produk** — 3 opsi, maks 70 karakter, mengandung kata kunci utama\n' +
      '2. **Ringkasan** — 2 kalimat yang menjual\n' +
      '3. **Poin manfaat** — 5-7 bullet, fokus pada manfaat\n' +
      '4. **Deskripsi lengkap** — 150-250 kata, enak dibaca di HP\n' +
      '5. **Spesifikasi** — tabel sederhana (bahan, ukuran, berat, garansi)\n' +
      '6. **Kata kunci SEO** — 8 kata kunci\n' +
      '7. **Ide bonus/urgensi** — 3 ide promo singkat',
  },
  {
    id: 'thread', label: 'Thread X / Twitter', hint: 'Rangkaian tweet yang enak dibaca', temp: 0.95, max: 3072,
    placeholder: 'Contoh: thread tentang 5 kebiasaan kecil yang bikin hidup lebih rapi',
    instruction:
      'Buat thread untuk X/Twitter berdasarkan brief.\nKeluarkan:\n' +
      '1. **Tweet pembuka** — 3 opsi hook (maks 240 karakter)\n' +
      '2. **Isi thread** — 8-12 tweet bernomor, masing-masing maks 240 karakter\n' +
      '3. **Tweet penutup** — rangkuman + ajakan (follow/retweet/komentar)\n' +
      '4. **3 ide kutipan** — kalimat yang bisa dijadikan gambar\n' +
      '5. **3 hashtag** yang relevan\n' +
      'Tulis dengan ritme cepat, kalimat pendek, dan hindari basa-basi.',
  },
  {
    id: 'seo', label: 'Riset Keyword & SEO', hint: 'Keyword, meta, outline artikel', temp: 0.7, max: 3072,
    placeholder: 'Contoh: website jasa laundry kiloan di Bandung',
    instruction:
      'Lakukan riset keyword & rencana SEO berdasarkan brief.\nKeluarkan:\n' +
      '1. **Keyword utama** — 1 kata kunci fokus + alasannya\n' +
      '2. **Keyword turunan** — 15 kata kunci (long-tail), dikelompokkan berdasarkan niat\n' +
      '3. **Meta title** — 3 opsi, maks 60 karakter\n' +
      '4. **Meta description** — 3 opsi, maks 155 karakter\n' +
      '5. **Outline artikel** — struktur H2/H3 yang siap ditulis\n' +
      '6. **5 ide judul artikel** dengan skor potensi klik (1-10)\n' +
      '7. **Internal link** — 5 ide tautan antar halaman\n' +
      '8. **FAQ** — 4 pertanyaan yang sering dicari orang',
  },
  {
    id: 'riset', label: 'Riset Web', hint: 'Cari sumber di web, lalu dirangkum', temp: 0.5, max: 3072,
    kind: 'webResearch', inputLabel: 'Topik yang mau diriset',
    placeholder: 'Contoh: tren thrifting di Indonesia tahun ini',
    instruction:
      'Kamu menerima topik riset beserta isi beberapa halaman web yang sudah dikumpulkan ' +
      'aplikasi (bagian SUMBER WEB).\nTulis hasil riset berdasarkan SUMBER itu saja:\n' +
      '1. **Ringkasan eksekutif** — 3-4 kalimat inti temuan\n' +
      '2. **Temuan utama** — 5-8 poin, setiap poin WAJIB menyebut sumber dengan format [Sumber N]\n' +
      '3. **Perbandingan sudut pandang** — bila ada perbedaan antar sumber, jelaskan\n' +
      '4. **Daftar sumber** — nomor, judul, dan URL tiap sumber\n' +
      '5. **Keterbatasan** — apa yang tidak terjawab oleh sumber\n' +
      'Jangan menambahi fakta yang tidak ada di sumber.',
  },
  {
    id: 'url', label: 'Baca & Ringkas URL', hint: 'Tempel link, dapat ringkasannya', temp: 0.4, max: 3072,
    kind: 'urlSummary', inputLabel: 'Tempel URL / domain',
    placeholder: 'Tempel URL halaman di sini, mis. https://contoh.com/artikel',
    instruction:
      'Kamu menerima isi sebuah halaman web yang sudah diambil aplikasi (bagian ISI HALAMAN).\n' +
      'Buat ringkasan halaman itu:\n' +
      '1. **TL;DR** — 2 kalimat inti\n' +
      '2. **Ringkasan lengkap** — 150-250 kata yang runtut\n' +
      '3. **Poin-poin kunci** — 5-8 bullet\n' +
      '4. **Kutipan penting** — maks 3 kutipan langsung bila ada\n' +
      '5. **Untuk siapa halaman ini berguna** — 1-2 kalimat\n' +
      'Jangan menambahi informasi yang tidak ada di halaman.',
  },
  {
    id: 'cs', label: 'Balas Chat Pembeli', hint: 'Balasan CS ramah & solutif', temp: 0.6,
    placeholder: 'Contoh: pembeli komplain pesanan telat 3 hari, minta refund',
    instruction:
      'Buat balasan chat customer service berdasarkan brief.\nKeluarkan 3 versi:\n' +
      '1. **Empati & solusi** — mengakui masalah, lalu kasih jalan keluar\n' +
      '2. **Singkat & to the point** — maks 3 kalimat, untuk chat cepat\n' +
      '3. **Versi lengkap** — sopan, terstruktur, cocok untuk email/komplain besar\n' +
      'Setiap versi: gunakan bahasa ramah, tidak defensif, sebutkan langkah konkret.\n' +
      'Tambahkan juga 3 template balasan cepat (stok, ongkir, estimasi sampai).',
  },
  {
    id: 'custom', label: 'Prompt Bebas', hint: 'Tulis instruksi apa saja', temp: 0.8, max: 4096,
    placeholder: 'Tulis instruksi apa saja di sini…',
    instruction: 'Ikuti instruksi berikut apa adanya.',
  },
];

export const LANGUAGES = [
  { code: 'id', label: 'Bahasa Indonesia' },
  { code: 'en', label: 'English' },
  { code: 'ms', label: 'Bahasa Melayu' },
  { code: 'ja', label: '日本語' },
  { code: 'zh', label: '中文' },
  { code: 'ar', label: 'العربية' },
  { code: 'es', label: 'Español' },
];

export const TONES = [
  { id: 'natural', label: 'Natural', instruction: 'natural, seperti ditulis manusia sungguhan, tidak kaku dan tidak berlebihan' },
  { id: 'profesional', label: 'Profesional', instruction: 'profesional, jelas, dan dapat dipercaya' },
  { id: 'padat', label: 'Padat & Tajam', instruction: 'padat, langsung ke inti, tanpa kata mubazir' },
  { id: 'bercerita', label: 'Bercerita', instruction: 'bercerita (storytelling): ada alur, tokoh atau situasi, dan emosi' },
  { id: 'elegan', label: 'Elegan', instruction: 'elegan, tenang, dan berkelas dengan diksi pilihan' },
  { id: 'santai', label: 'Santai', instruction: 'santai, akrab, dan mengalir seperti ngobrol' },
  { id: 'persuasif', label: 'Persuasif', instruction: 'persuasif, memancing rasa penasaran, dan mendorong aksi' },
  { id: 'informatif', label: 'Informatif', instruction: 'informatif dan objektif: utamakan fakta, data, dan penjelasan runtut' },
  { id: 'puitis', label: 'Puitis', instruction: 'puitis dan penuh citra rasa; ritme kalimat dijaga' },
  { id: 'lucu', label: 'Lucu', instruction: 'lucu, jenaka, dan menghibur tanpa berlebihan' },
  { id: 'formal', label: 'Formal / Akademik', instruction: 'formal, baku, dan terstruktur seperti dokumen resmi' },
  { id: 'inspiratif', label: 'Inspiratif', instruction: 'inspiratif, hangat, dan memotivasi' },
];

export const LENGTHS = [
  { id: 'singkat', label: 'Singkat', instruction: 'sangat ringkas, maksimal sekitar 120 kata' },
  { id: 'sedang', label: 'Sedang', instruction: 'proporsional, sekitar 250-400 kata' },
  { id: 'panjang', label: 'Panjang', instruction: 'mendalam dan lengkap, 700 kata atau lebih bila perlu' },
];

// Model chat yang HIDUP di Groq per September 2026. Opsi "auto" merotasi
// semuanya tiap generate + pindah otomatis saat 429 / 5xx / error.
export const MODELS = [
  { id: 'openai/gpt-oss-120b', label: 'GPT-OSS 120B', note: 'Paling kuat, output paling rapi', ctx: 131072 },
  { id: 'openai/gpt-oss-20b', label: 'GPT-OSS 20B', note: 'Kuat tapi tetap cepat', ctx: 131072 },
  { id: 'qwen/qwen3.8-27b', label: 'Qwen3.8 27B', note: 'Seimbang untuk bahasa & logika', ctx: 131072 },
  { id: 'allam-2-7b', label: 'Allam 2 7B', note: 'Ringan, konteks kecil', ctx: 4096 },
];

export const AUTO_MODEL = {
  id: 'auto',
  label: 'Auto (muter)',
  note: 'Rotasi model tiap generate + pindah otomatis saat model sibuk atau error',
};
