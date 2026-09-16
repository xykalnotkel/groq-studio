import 'package:flutter/material.dart';

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
          'Setelah daftar, berikan 3 rekomendasi terbaik dengan tanda ⭐ plus '
          'satu kalimat alasan kenapa judul itu kuat.',
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
          '6. Baris terakhir: "Meta description:" diikuti 1 kalimat (maks 155 karakter)',
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
          '4. Deskripsi lengkap (300-500 kata) dengan emoji secukupnya'
          ' dan struktur yang enak dibaca di HP\n'
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
          'pertanyaan, promo, tips)\n'
          '2. Setiap caption: baris hook di awal + isi + ajakan (CTA)\n'
          '3. 15 hashtag relevan di bagian akhir\n'
          '4. 3 ide teks untuk gambar/story (maks 8 kata)',
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
          'dan unik/nyeleneh. Beri tanda ✅ pada 3 favoritmu.',
    ),
    GenerationMode(
      id: 'rilis',
      label: 'Catatan Rilis',
      icon: Icons.rocket_launch_rounded,
      hint: 'Changelog / release notes rapi',
      placeholder: 'Contoh: versi 2.1, ada mode gelap, perbaikan bug login',
      color: Color(0xFF38BDF8),
      temperature: 0.5,
      instruction:
          'Ubah catatan di brief menjadi release notes profesional.\n'
          'Format:\n'
          '## Versi x.y\n'
          'Satu kalimat ringkasan.\n'
          '### ✨ Yang baru — poin-poin\n'
          '### 🐛 Perbaikan — poin-poin\n'
          '### ⚡ Peningkatan — poin-poin\n'
          'Akhiri dengan kalimat ucapan terima kasih untuk pengguna.',
    ),
    GenerationMode(
      id: 'iklan',
      label: 'Copy Iklan',
      icon: Icons.campaign_rounded,
      hint: 'Hook, body, dan CTA yang menjual',
      placeholder: 'Contoh: kursus public speaking online 4 minggu',
      color: Color(0xFFEF4444),
      temperature: 0.9,
      instruction:
          'Tulis copy iklan yang menjual.\n'
          'Keluarkan:\n'
          '1. 5 hook/headline (maks 10 kata)\n'
          '2. Satu naskah iklan lengkap dengan struktur: hook → masalah → '
          'solusi → bukti/manfaat → penawaran → CTA\n'
          '3. 3 variasi ajakan (CTA)\n'
          '4. 3 ide judul untuk gambar iklan',
    ),
    GenerationMode(
      id: 'email',
      label: 'Email & Pengumuman',
      icon: Icons.mail_rounded,
      hint: 'Email, pengumuman, chat broadcast',
      placeholder: 'Contoh: pengumuman maintenance server jam 2 pagi',
      color: Color(0xFFA78BFA),
      temperature: 0.6,
      instruction:
          'Tulis email/pengumuman resmi berdasarkan brief.\n'
          'Keluarkan: 3 opsi subjek (maks 8 kata), salam pembuka, '
          'isi yang langsung ke inti dengan poin-poin bila perlu, '
          'dan penutup + nama pengirim yang bisa diganti.\n'
          'Sertakan juga versi singkat (maks 40 kata) untuk chat/WA.',
    ),
    GenerationMode(
      id: 'ide',
      label: 'Brainstorming',
      icon: Icons.psychology_rounded,
      hint: 'Daftar ide + langkah eksekusi',
      placeholder: 'Contoh: ide konten 30 hari untuk akun bisnis laundry',
      color: Color(0xFF2DD4BF),
      temperature: 1.0,
      instruction:
          'Lakukan brainstorming berdasarkan brief.\n'
          'Keluarkan minimal 12 ide yang konkret dan beragam.\n'
          'Untuk setiap ide: nama ide, 1 kalimat penjelasan, '
          'tingkat usaha (mudah/sedang/berat), dan 1 langkah pertama '
          'yang bisa langsung dikerjakan.\n'
          'Akhiri dengan 3 ide terbaik + alasannya.',
    ),
    GenerationMode(
      id: 'script',
      label: 'Script Video',
      icon: Icons.smart_display_rounded,
      hint: 'Naskah YouTube/TikTok/Reels siap rekam',
      placeholder: 'Contoh: video 60 detik tips hemat uang untuk mahasiswa',
      color: Color(0xFFFF5C5C),
      temperature: 0.95,
      maxTokens: 3072,
      instruction:
          'Tulis naskah video berdasarkan brief.\n'
          'Keluarkan dengan struktur berikut:\n'
          '1. **Hook (0-3 detik)** — 3 opsi kalimat pembuka yang bikin orang '
          'berhenti scroll\n'
          '2. **Naskah lengkap** — dipecah per adegan; tiap adegan berisi: '
          'menit/detik, apa yang diucapkan (tulis persis seperti ngomong), '
          'dan teks yang tampil di layar\n'
          '3. **Ide visual** — 5 ide B-roll/gambar pendukung per adegan\n'
          '4. **CTA penutup** — 2 opsi ajakan (subscribe/follow/komen)\n'
          '5. **Judul video** — 3 opsi (maks 60 karakter)\n'
          '6. **Deskripsi video** — 2 paragraf + 10 hashtag\n'
          'Tulis dengan gaya ngobrol, kalimat pendek, dan mudah diucapkan.',
    ),
    GenerationMode(
      id: 'gambar',
      label: 'Prompt Gambar',
      icon: Icons.image_rounded,
      hint: 'Prompt untuk Midjourney/SDXL/Flux',
      placeholder: 'Contoh: ilustrasi kopi susu estetik untuk feed Instagram',
      color: Color(0xFF6EE7B7),
      temperature: 0.9,
      instruction:
          'Ubah brief menjadi prompt untuk AI image generator '
          '(Midjourney / Stable Diffusion / Flux / DALL·E).\n'
          'Keluarkan:\n'
          '1. **Prompt utama (English)** — satu paragraf padat: subjek, '
          'detail, gaya, komposisi, pencahayaan, lensa, suasana, palet warna\n'
          '2. **Prompt versi Indonesia** — terjemahan naturalnya\n'
          '3. **Negative prompt** — hal yang harus dihindari\n'
          '4. **Variasi** — 3 alternatif prompt dengan gaya berbeda '
          '(fotorealistik, ilustrasi flat, 3D render, sinematik)\n'
          '5. **Parameter saran** — aspect ratio, style strength, seed, '
          'dan model yang cocok\n'
          'Prompt harus spesifik, deskriptif, dan siap ditempel apa adanya.',
    ),
    GenerationMode(
      id: 'kalender',
      label: 'Kalender Konten',
      icon: Icons.calendar_month_rounded,
      hint: 'Jadwal konten 7/14/30 hari',
      placeholder: 'Contoh: akun Instagram bisnis laundry di dekat kampus',
      color: Color(0xFFF0ABFC),
      temperature: 0.95,
      maxTokens: 3072,
      instruction:
          'Buat kalender konten berdasarkan brief.\n'
          'Format: tabel dengan kolom Hari | Tema | Ide konten | Format '
          '(Reels/Carousel/Story/Feed) | Hook/teks pembuka | CTA.\n'
          'Buat 30 hari bila tidak disebutkan lain.\n'
          'Setiap ide harus konkret, beragam (edukasi, hiburan, promo, '
          'testimoni, behind the scene), dan bisa langsung dikerjakan.\n'
          'Akhiri dengan 5 ide konten terbaik yang paling berpotensi viral '
          'beserta alasannya.',
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
