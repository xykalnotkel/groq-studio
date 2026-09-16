import 'package:flutter/material.dart';

/// Jenis alur kerja sebuah mode.
enum ModeKind {
  /// Mode standar: brief pengguna langsung dikerjakan model.
  standard,

  /// Aplikasi mencari hasil pencarian sendiri, membuka halamannya,
  /// lalu model merangkum dari sumber yang ditemukan.
  webResearch,

  /// Aplikasi membuka URL yang diberikan pengguna, lalu model
  /// meringkas isinya.
  urlSummary,
}

/// Satu "mode" generate: judul, deskripsi, artikel, dll.
class GenerationMode {
  const GenerationMode({
    required this.id,
    required this.label,
    required this.icon,
    required this.hint,
    required this.placeholder,
    required this.instruction,
    required this.color,
    this.temperature = 0.8,
    this.maxTokens = 2048,
    this.kind = ModeKind.standard,
    this.inputLabel = 'Ceritakan sebentar',
    this.engines = const <String>[],
  });

  final String id;
  final String label;
  final IconData icon;
  final String hint;
  final String placeholder;
  final String instruction;
  final Color color;
  final double temperature;
  final int maxTokens;
  final ModeKind kind;

  /// Label bagian input utama (berubah untuk mode URL/riset).
  final String inputLabel;

  /// Daftar engine target (prompt gambar/video). Kosong = tidak ada pilihan.
  final List<String> engines;

  bool get usesEngines => engines.isNotEmpty;

  static const List<GenerationMode> values = <GenerationMode>[
    GenerationMode(
      id: 'judul',
      label: 'Judul',
      icon: Icons.text_fields_rounded,
      hint: 'Bikin opsi judul yang bikin orang klik',
      placeholder: 'Contoh: aplikasi pencatat keuangan untuk anak kos',
      color: Color(0xFF7C5CFF),
      temperature: 1.0,
      instruction:
          'Buatkan 10 opsi judul/headline yang menarik dari brief di bawah.\n'
          'Aturan: beri nomor, maksimal 12 kata per judul, variasikan gayanya '
          '(ada yang pakai angka, pertanyaan, kata "rahasia", dan manfaat).\n'
          'Setelah daftar, berikan 3 rekomendasi terbaik dengan tanda '
          '"[FAVORIT]" di depan nomor, plus satu kalimat alasan kenapa '
          'judul itu kuat.',
    ),
    GenerationMode(
      id: 'deskripsi',
      label: 'Deskripsi',
      icon: Icons.short_text_rounded,
      hint: 'Paragraf deskripsi singkat & menjual',
      placeholder: 'Contoh: aplikasi belajar bahasa Jepang dengan flashcard',
      color: Color(0xFF22D3EE),
      temperature: 0.8,
      instruction:
          'Tulis deskripsi singkat (2 paragraf) tentang hal di brief.\n'
          'Paragraf 1: apa itu dan untuk siapa.\n'
          'Paragraf 2: manfaat utama yang paling terasa.\n'
          'Akhiri dengan 5 poin ringkas "Kenapa ini menarik".',
    ),
    GenerationMode(
      id: 'artikel',
      label: 'Artikel',
      icon: Icons.article_rounded,
      hint: 'Artikel lengkap + outline + FAQ',
      placeholder: 'Contoh: cara mengatur keuangan bulanan untuk pemula',
      color: Color(0xFF4ADE80),
      temperature: 0.7,
      maxTokens: 4096,
      instruction:
          'Tulis artikel lengkap berdasarkan brief.\n'
          'Struktur wajib:\n'
          '1. Judul utama (H1)\n'
          '2. Paragraf pembuka yang menarik\n'
          '3. 4-6 subjudul (H2) dengan isi yang benar-benar bernilai, '
          'boleh berisi poin-poin atau langkah praktis\n'
          '4. Kesimpulan + ajakan bertindak\n'
          '5. Bagian "FAQ" berisi 3 pertanyaan & jawaban\n'
          '6. Baris terakhir: "Meta description:" diikuti 1 kalimat '
          '(maks 155 karakter)',
    ),
    GenerationMode(
      id: 'penjelasan',
      label: 'Penjelasan Aplikasi',
      icon: Icons.phone_android_rounded,
      hint: '"Aplikasi ini apa?" — siap tempel',
      placeholder:
          'Contoh: saya baru saja bikin aplikasi pencatat jadwal sholat',
      color: Color(0xFFFF8A4C),
      temperature: 0.7,
      instruction:
          'Jelaskan aplikasi/produk di brief dengan gaya "penjelasan aplikasi".\n'
          'Wajib memuat bagian:\n'
          '## Apa ini — 1 paragraf penjelasan sederhana\n'
          '## Masalah yang diselesaikan — poin-poin\n'
          '## Fitur utama — 5 poin dengan penjelasan 1 kalimat\n'
          '## Untuk siapa — sebutkan 3 tipe pengguna\n'
          '## Cara pakai — langkah 1-4\n'
          '## Kenapa beda — 3 poin\n'
          'Tutup dengan satu kalimat rangkuman yang mudah diingat.',
    ),
    GenerationMode(
      id: 'store',
      label: 'Play Store',
      icon: Icons.storefront_rounded,
      hint: 'Listing store: judul, deskripsi, keyword',
      placeholder: 'Contoh: aplikasi edit foto dengan efek film klasik',
      color: Color(0xFFFF4D9D),
      temperature: 0.8,
      instruction:
          'Buatkan materi listing toko aplikasi (Google Play / App Store).\n'
          'Keluarkan:\n'
          '1. Nama aplikasi (maks 30 karakter) + 3 alternatif\n'
          '2. Judul/subtitle promosi (maks 80 karakter)\n'
          '3. Deskripsi singkat (maks 80 karakter)\n'
          '4. Deskripsi lengkap (300-500 kata) dengan struktur yang enak '
          'dibaca di HP, TANPA emoji sama sekali\n'
          '5. 5 kata kunci utama (keyword field)\n'
          '6. 3 ide kalimat "What\'s New"',
    ),
    GenerationMode(
      id: 'caption',
      label: 'Caption & Hashtag',
      icon: Icons.tag_rounded,
      hint: 'Caption Instagram/TikTok + hashtag',
      placeholder: 'Contoh: promo kopi susu literan di kampus',
      color: Color(0xFFF472B6),
      temperature: 1.0,
      instruction:
          'Buatkan materi media sosial.\n'
          'Keluarkan:\n'
          '1. 5 opsi caption dengan gaya berbeda (cerita, lucu, '
          'pertanyaan, promo, tips) — semua tanpa emoji\n'
          '2. Setiap caption: baris hook di awal + isi + ajakan (CTA)\n'
          '3. 15 hashtag relevan di bagian akhir\n'
          '4. 3 ide teks untuk gambar/story (maks 8 kata)',
    ),
    GenerationMode(
      id: 'bio',
      label: 'Bio Sosmed / Akun',
      icon: Icons.person_rounded,
      hint: 'Bio IG/TikTok/X & bio akun aplikasi',
      placeholder:
          'Contoh: akun Instagram toko kue rumahan di Bandung, target ibu muda',
      color: Color(0xFFC084FC),
      temperature: 0.95,
      instruction:
          'Buatkan kumpulan bio berdasarkan brief.\n'
          'Keluarkan:\n'
          '1. **Bio Instagram** — 4 opsi, maks 150 karakter per bio, '
          'ada yang pakai pemisah "|" dan yang bentuk kalimat\n'
          '2. **Bio TikTok** — 3 opsi, maks 80 karakter, punchy\n'
          '3. **Bio X/Twitter** — 3 opsi, maks 160 karakter\n'
          '4. **Bio WhatsApp / profil akun aplikasi** — 2 opsi singkat\n'
          '5. **Nama tampilan (display name)** — 3 opsi beserta '
          'username yang matching (huruf kecil, tanpa spasi)\n'
          'Syarat: tanpa emoji, tetap berkarakter, cantumkan kata kunci '
          'yang relevan supaya mudah dicari.',
    ),
    GenerationMode(
      id: 'nama',
      label: 'Ide Nama',
      icon: Icons.lightbulb_rounded,
      hint: 'Nama brand/produk + maknanya',
      placeholder: 'Contoh: aplikasi pengingat minum air berbasis AI',
      color: Color(0xFFFBBF24),
      temperature: 1.1,
      instruction:
          'Beri 15 ide nama untuk hal di brief.\n'
          'Untuk setiap nama sebutkan: nama, 1 kalimat makna/filosofinya, '
          'dan kemudahan diingat (mudah/sedang/sulit).\n'
          'Kelompokkan menjadi: pendek & modern, bermakna lokal, '
          'dan unik/nyeleneh. Beri tanda "[FAVORIT]" pada 3 pilihan terbaikmu.',
    ),
    GenerationMode(
      id: 'rilis',
      label: 'Catatan Rilis',
      icon: Icons.rocket_launch_rounded,
      hint: 'Changelog / release notes rapi',
      placeholder:
          'Contoh: aplikasi kasir tambah fitur scan barcode & ekspor PDF',
      color: Color(0xFF38BDF8),
      temperature: 0.5,
      instruction:
          'Tulis catatan rilis (release notes) berdasarkan brief.\n'
          'Keluarkan 3 versi:\n'
          '1. **Versi lengkap** — pembuka hangat, daftar perubahan '
          'dikelompokkan (Baru / Peningkatan / Perbaikan), penutup\n'
          '2. **Versi singkat** — 4-6 baris untuk dialog update di aplikasi\n'
          '3. **Versi media sosial** — 2-3 kalimat santai untuk pengumuman\n'
          'Gunakan penomoran versi contoh seperti v2.1.0 dan tanggal relatif '
          '"minggu ini" bila tidak disebutkan.',
    ),
    GenerationMode(
      id: 'iklan',
      label: 'Copy Iklan',
      icon: Icons.campaign_rounded,
      hint: 'Hook, body, dan CTA yang menjual',
      placeholder: 'Contoh: jasa cuci sepatu premium, antar-jemput gratis',
      color: Color(0xFFFB7185),
      temperature: 0.9,
      instruction:
          'Buat copy iklan berdasarkan brief.\n'
          'Keluarkan:\n'
          '1. **3 hook pembuka** — kalimat pertama yang menghentikan scroll\n'
          '2. **Body copy** — 2 versi: pendek (50 kata) dan sedang (120 kata)\n'
          '3. **5 CTA** — ajakan bertindak yang bervariasi\n'
          '4. **Versi iklan Meta/Instagram** — primary text (125 karakter '
          'pertama kuat), headline (maks 40 karakter), deskripsi (maks 30 '
          'karakter)\n'
          '5. **Versi Google Ads** — 3 headline (maks 30 karakter) + '
          '2 deskripsi (maks 90 karakter)\n'
          'Tanpa klaim berlebihan yang tidak bisa dibuktikan.',
    ),
    GenerationMode(
      id: 'email',
      label: 'Email & Pengumuman',
      icon: Icons.mail_rounded,
      hint: 'Email resmi + versi singkat WA',
      placeholder:
          'Contoh: undangan rapat evaluasi program untuk tim, Kamis jam 10',
      color: Color(0xFFA3E635),
      temperature: 0.6,
      instruction:
          'Tulis email/pengumuman berdasarkan brief.\n'
          'Keluarkan:\n'
          '1. **Subjek email** — 3 opsi, maks 60 karakter\n'
          '2. **Isi email lengkap** — pembuka sopan, isi jelas, penutup + '
          'ttd placeholder [Nama Kamu]\n'
          '3. **Versi singkat** — untuk chat WhatsApp/Slack (maks 60 kata)\n'
          '4. **Versi follow-up** — jika tidak ada balasan setelah 3 hari',
    ),
    GenerationMode(
      id: 'ide',
      label: 'Brainstorming',
      icon: Icons.psychology_rounded,
      hint: 'Daftar ide + langkah eksekusi',
      placeholder: 'Contoh: konten edukasi keuangan untuk fresh graduate',
      color: Color(0xFFFB923C),
      temperature: 1.0,
      maxTokens: 3072,
      instruction:
          'Lakukan brainstorming berdasarkan brief.\n'
          'Keluarkan:\n'
          '1. **15 ide** bernomor, masing-masing 1 kalimat kuat\n'
          '2. **3 ide terbaik** dijabarkan: kenapa potensial, targetnya, '
          'dan cara memulainya\n'
          '3. **Langkah eksekusi 7 hari** untuk ide terbaik\n'
          '4. **Risiko & cara mengantisipasinya** — 3 poin\n'
          '5. **Pertanyaan yang perlu dijawab** sebelum mulai — 5 pertanyaan',
    ),
    GenerationMode(
      id: 'script',
      label: 'Script Video',
      icon: Icons.play_circle_rounded,
      hint: 'Naskah YouTube/TikTok/Reels',
      placeholder:
          'Contoh: video 60 detik tentang cara menabung 1 juta pertama',
      color: Color(0xFFE879F9),
      temperature: 0.95,
      maxTokens: 3072,
      instruction:
          'Buat script video berdasarkan brief.\n'
          'Keluarkan:\n'
          '1. **Hook 3 detik pertama** — 3 opsi\n'
          '2. **Script lengkap** dengan format: [VISUAL] baris deskripsi '
          'apa yang terlihat, lalu baris dialog/voice over di bawahnya. '
          'Durasi total disesuaikan panjang yang diminta.\n'
          '3. **CTA penutup** — ajakan like/follow/komentar\n'
          '4. **Judul video** — 3 opsi + 10 hashtag\n'
          '5. **Catatan editing** — tempo, musik, dan teks layar penting',
    ),
    GenerationMode(
      id: 'gambar',
      label: 'Prompt Gambar',
      icon: Icons.image_rounded,
      hint: 'Prompt Midjourney/Flux/SDXL/DALL-E',
      placeholder:
          'Contoh: ilustrasi warung kopi futuristik di pinggir sawah, senja',
      color: Color(0xFF2DD4BF),
      temperature: 0.9,
      engines: <String>['Midjourney', 'Flux', 'SDXL', 'DALL-E'],
      instruction:
          'Buat prompt gambar AI berdasarkan brief.\n'
          'Keluarkan struktur berikut:\n'
          '1. **Prompt utama (English)** — kalimat deskriptif padat: subjek, '
          'aksi, lingkungan, pencahayaan, mood, komposisi, gaya, detail lensa/'
          'kamera bila relevan\n'
          '2. **3 variasi** — beda gaya (mis. fotorealistik, ilustrasi, 3D '
          'render) tetap dari brief yang sama\n'
          '3. **Parameter** sesuai engine target:\n'
          '   - Midjourney: --ar, --v, --stylize, --chaos\n'
          '   - Flux: guidance scale, jumlah step, resolusi\n'
          '   - SDXL/SD: CFG scale, step, sampler, resolusi, seed\n'
          '   - DALL-E: ukuran (size), style (vivid/natural), quality\n'
          '4. **Negative prompt** — apa yang harus dihindar (tangan rusak, '
          'wajah cacat, teks, watermark, dll.), versi lengkap untuk SDXL/Flux '
          'dan versi ringkas untuk yang lain\n'
          '5. **Tips singkat** — 2-3 kalimat cara memakainya di engine tersebut\n'
          'Prompt utama WAJIB dalam bahasa Inggris; penjelasan boleh bahasa '
          'keluaran yang diminta.',
    ),
    GenerationMode(
      id: 'video-prompt',
      label: 'Prompt Video',
      icon: Icons.movie_rounded,
      hint: 'Prompt Sora / Veo / Runway / Kling',
      placeholder:
          'Contoh: drone shot kota Jakarta saat hujan malam hari, sinematik',
      color: Color(0xFF818CF8),
      temperature: 0.9,
      engines: <String>['Sora', 'Veo', 'Runway', 'Kling'],
      instruction:
          'Buat prompt video AI berdasarkan brief.\n'
          'Keluarkan struktur berikut:\n'
          '1. **Prompt utama (English)** — satu paragraf padat memuat: subjek, '
          'aksi/gerakan, pergerakan kamera (pan, dolly, orbit, handheld), '
          'pencahayaan, mood, gaya sinematik, durasi yang disarankan\n'
          '2. **3 variasi shot** — mis. wide establishing, close-up detail, '
          'dan FPV/dynamic, tetap dari brief yang sama\n'
          '3. **Parameter sesuai engine target**:\n'
          '   - Sora: durasi, resolusi/orientasi, gaya\n'
          '   - Veo: aspect ratio, gaya (cinematic/documentary), durasi\n'
          '   - Runway: Gen-3/Gen-4, durasi (5/10 detik), camera control, '
          'motion intensity\n'
          '   - Kling: durasi, mode (standard/professional), creativity & '
          'relevance scale\n'
          '4. **Negative prompt** — hal yang dihindari (morphing aneh, '
          'wajah rusak, teks, watermark)\n'
          '5. **Saran loop/transisi** bila cocok untuk konten sosial\n'
          'Prompt utama WAJIB dalam bahasa Inggris; penjelasan boleh bahasa '
          'keluaran yang diminta.',
    ),
    GenerationMode(
      id: 'kalender',
      label: 'Kalender Konten',
      icon: Icons.calendar_month_rounded,
      hint: 'Jadwal konten 7–30 hari',
      placeholder: 'Contoh: akun TikTok kedai kopi, target mahasiswa',
      color: Color(0xFFF97316),
      temperature: 0.95,
      maxTokens: 3072,
      instruction:
          'Buat kalender konten berdasarkan brief.\n'
          'Keluarkan:\n'
          '1. **Strategi singkat** — 3 pilar konten utama\n'
          '2. **Kalender 14 hari** dalam tabel: Hari | Format | Ide Konten | '
          'Hook pembuka | Jam tayang\n'
          '3. **5 ide konten evergreen** yang bisa dipakai kapan saja\n'
          '4. **3 ide serial/konten berulang** (mis. "Tip Senin")\n'
          '5. **Metrik yang perlu dipantau** — 5 metrik',
    ),
    GenerationMode(
      id: 'terjemah',
      label: 'Terjemah & Parafrase',
      icon: Icons.translate_rounded,
      hint: 'Terjemahan natural + 3 parafrase',
      placeholder: 'Tempel teks yang mau diterjemahkan / diparafrase di sini',
      color: Color(0xFF14B8A6),
      temperature: 0.5,
      instruction:
          'Kerjakan teks pengguna:\n'
          '1. **Terjemahan natural** — jika teks berbahasa Indonesia, '
          'terjemahkan ke Inggris; jika bahasa lain, terjemahkan ke bahasa '
          'keluaran yang diminta. Hasil harus luwes, bukan terjemahan kaku.\n'
          '2. **3 parafrase** — tulis ulang dengan gaya berbeda: lebih formal, '
          'lebih santai, lebih ringkas\n'
          '3. **Catatan** — istilah yang sulit diterjemahkan dan alasan '
          'pemilihan katanya (maks 3 poin)',
    ),
    GenerationMode(
      id: 'produk',
      label: 'Deskripsi Produk',
      icon: Icons.shopping_bag_rounded,
      hint: 'Judul, bullet, SEO toko online',
      placeholder:
          'Contoh: tas ransel laptop anti air bahan kanvas, harga 350 ribuan',
      color: Color(0xFFFFB347),
      temperature: 0.8,
      instruction:
          'Buat materi deskripsi produk untuk toko online.\n'
          'Keluarkan:\n'
          '1. **Judul produk** — 3 opsi, maks 70 karakter, mengandung kata '
          'kunci utama\n'
          '2. **Ringkasan** — 2 kalimat yang menjual\n'
          '3. **Poin manfaat** — 5-7 bullet, fokus pada manfaat bukan sekadar '
          'spesifikasi\n'
          '4. **Deskripsi lengkap** — 150-250 kata, enak dibaca di HP\n'
          '5. **Spesifikasi** — tabel sederhana (bahan, ukuran, berat, garansi)\n'
          '6. **Kata kunci SEO** — 8 kata kunci\n'
          '7. **Ide bonus/urgensi** — 3 ide promo singkat',
    ),
    GenerationMode(
      id: 'thread',
      label: 'Thread X / Twitter',
      icon: Icons.forum_rounded,
      hint: 'Rangkaian tweet yang bikin orang baca sampai habis',
      placeholder: 'Contoh: thread tentang 5 kebiasaan kecil yang bikin hidup lebih rapi',
      color: Color(0xFF60A5FA),
      temperature: 0.95,
      maxTokens: 3072,
      instruction:
          'Buat thread untuk X/Twitter berdasarkan brief.\n'
          'Keluarkan:\n'
          '1. **Tweet pembuka** — 3 opsi hook (maks 240 karakter), '
          'harus bikin orang berhenti scroll\n'
          '2. **Isi thread** — 8-12 tweet bernomor, masing-masing maks 240 '
          'karakter, satu ide per tweet\n'
          '3. **Tweet penutup** — rangkuman + ajakan (follow/retweet/komentar)\n'
          '4. **3 ide kutipan** — kalimat yang bisa dijadikan gambar\n'
          '5. **3 hashtag** yang relevan\n'
          'Tulis dengan ritme cepat, kalimat pendek, dan hindari basa-basi.',
    ),
    GenerationMode(
      id: 'seo',
      label: 'Riset Keyword & SEO',
      icon: Icons.travel_explore_rounded,
      hint: 'Keyword, meta, dan outline artikel',
      placeholder: 'Contoh: website jasa laundry kiloan di Bandung',
      color: Color(0xFF34D399),
      temperature: 0.7,
      maxTokens: 3072,
      instruction:
          'Lakukan riset keyword & rencana SEO berdasarkan brief.\n'
          'Keluarkan:\n'
          '1. **Keyword utama** — 1 kata kunci fokus + alasannya\n'
          '2. **Keyword turunan** — 15 kata kunci (long-tail), dikelompokkan '
          'berdasarkan niat: informatif, komersial, transaksional\n'
          '3. **Meta title** — 3 opsi, maks 60 karakter\n'
          '4. **Meta description** — 3 opsi, maks 155 karakter\n'
          '5. **Outline artikel** — struktur H2/H3 yang siap ditulis\n'
          '6. **5 ide judul artikel** dengan skor potensi klik (1-10)\n'
          '7. **Internal link** — 5 ide tautan antar halaman\n'
          '8. **FAQ** — 4 pertanyaan yang sering dicari orang',
    ),
    GenerationMode(
      id: 'riset',
      label: 'Riset Web',
      icon: Icons.public_rounded,
      hint: 'Cari sumber di web, lalu dirangkum',
      placeholder: 'Contoh: tren thrifting di Indonesia tahun ini',
      color: Color(0xFF0EA5E9),
      temperature: 0.5,
      maxTokens: 3072,
      kind: ModeKind.webResearch,
      inputLabel: 'Topik yang mau diriset',
      instruction:
          'Kamu menerima topik riset beserta isi beberapa halaman web yang '
          'sudah dikumpulkan aplikasi (bagian SUMBER WEB).\n'
          'Tulis hasil riset berdasarkan SUMBER itu saja:\n'
          '1. **Ringkasan eksekutif** — 3-4 kalimat inti temuan\n'
          '2. **Temuan utama** — 5-8 poin, setiap poin WAJIB menyebut sumber '
          'dengan format [Sumber N]\n'
          '3. **Perbandingan sudut pandang** — bila ada perbedaan antar '
          'sumber, jelaskan\n'
          '4. **Daftar sumber** — nomor, judul, dan URL tiap sumber\n'
          '5. **Keterbatasan** — apa yang tidak terjawab oleh sumber\n'
          'Jangan menambahi fakta yang tidak ada di sumber. Jika sumber '
          'minim, katakan apa adanya.',
    ),
    GenerationMode(
      id: 'url',
      label: 'Baca & Ringkas URL',
      icon: Icons.link_rounded,
      hint: 'Tempel link, dapat ringkasannya',
      placeholder:
          'Tempel URL halaman di sini, mis. https://contoh.com/artikel',
      color: Color(0xFFF43F5E),
      temperature: 0.4,
      maxTokens: 3072,
      kind: ModeKind.urlSummary,
      inputLabel: 'Tempel URL / domain',
      instruction:
          'Kamu menerima isi sebuah halaman web yang sudah diambil aplikasi '
          '(bagian ISI HALAMAN).\n'
          'Buat ringkasan halaman itu:\n'
          '1. **TL;DR** — 2 kalimat inti\n'
          '2. **Ringkasan lengkap** — 150-250 kata yang runtut\n'
          '3. **Poin-poin kunci** — 5-8 bullet\n'
          '4. **Kutipan penting** — maks 3 kutipan langsung bila ada\n'
          '5. **Untuk siapa halaman ini berguna** — 1-2 kalimat\n'
          'Jangan menambahi informasi yang tidak ada di halaman.',
    ),
    GenerationMode(
      id: 'cs',
      label: 'Balas Chat Pembeli',
      icon: Icons.support_agent_rounded,
      hint: 'Balasan CS ramah untuk komplain, tanya, atau nego',
      placeholder:
          'Contoh: pembeli komplain pesanan telat 3 hari, minta refund',
      color: Color(0xFFF87171),
      temperature: 0.6,
      instruction:
          'Buat balasan chat customer service berdasarkan brief.\n'
          'Keluarkan 3 versi:\n'
          '1. **Empati & solusi** — mengakui masalah, lalu kasih jalan keluar\n'
          '2. **Singkat & to the point** — maks 3 kalimat, untuk chat cepat\n'
          '3. **Versi lengkap** — sopan, terstruktur, cocok untuk email/'
          'komplain besar\n'
          'Setiap versi: gunakan bahasa ramah, tidak defensif, sebutkan '
          'langkah konkret yang akan dilakukan, dan akhiri dengan kalimat '
          'yang menenangkan.\n'
          'Tambahkan juga 3 template balasan cepat untuk pertanyaan yang '
          'sering muncul (stok, ongkir, estimasi sampai).',
    ),
    GenerationMode(
      id: 'custom',
      label: 'Prompt Bebas',
      icon: Icons.auto_awesome_rounded,
      hint: 'Tulis apa saja, model akan mengerjakan',
      placeholder: 'Tulis instruksi apa saja di sini…',
      color: Color(0xFF94A3B8),
      temperature: 0.8,
      maxTokens: 4096,
      instruction: 'Ikuti instruksi berikut apa adanya.',
    ),
  ];

  static GenerationMode fromId(String id) =>
      values.firstWhere((m) => m.id == id, orElse: () => values.first);
}
