// Konfigurasi bersama untuk seluruh halaman web XyStudio AI.
export const APP = {
  name: 'XyStudio AI',
  brand: 'XyVerse',
  credit: 'Built in XyVerse',
  version: '2.0.0',
  tagline: 'Tulis apa saja, jadi cepat',
  description:
    'Studio menulis AI: judul, artikel, caption, script video, prompt gambar, dan 20 mode lainnya. Ditenagai Groq.',
  waChannelUrl: 'https://whatsapp.com/channel/0029VbB7nwuJZg3ym6UQ4Z1L',
  waChannelName: 'Saluran WA XyVerse',
  bugReportUrl:
    'https://wa.me/6283116632566?text=Halo%20XyVerse!%20Saya%20mau%20lapor%20bug%20di%20XyStudio%20AI%20(web):%0A%0A%E2%80%A2%20Halaman:%0A%E2%80%A2%20Mode:%0A%E2%80%A2%20Cerita%20singkat:',
  githubUrl: 'https://github.com/xykalnotkel/groq-studio',
  keysUrl: 'https://console.groq.com/keys',
  apkUrl:
    'https://github.com/xykalnotkel/groq-studio/releases/download/v1.1.0/GroqStudio-1.1.0-arm64-v8a.apk',
  releasesUrl: 'https://github.com/xykalnotkel/groq-studio/releases/latest',
};

// Mode generate — sama dengan versi Android supaya hasilnya konsisten.
export const MODES = [
  { id: 'judul', label: 'Judul', icon: 'text', hint: 'Opsi judul yang bikin orang klik', temp: 1.0 },
  { id: 'deskripsi', label: 'Deskripsi', icon: 'text', hint: 'Paragraf deskripsi singkat & menjual', temp: 0.8 },
  { id: 'artikel', label: 'Artikel', icon: 'doc', hint: 'Artikel lengkap + outline + FAQ', temp: 0.7, max: 4096 },
  { id: 'penjelasan', label: 'Penjelasan Aplikasi', icon: 'phone', hint: '"Aplikasi ini apa?" siap tempel', temp: 0.7 },
  { id: 'store', label: 'Play Store', icon: 'store', hint: 'Judul, deskripsi, keyword listing', temp: 0.8 },
  { id: 'caption', label: 'Caption & Hashtag', icon: 'tag', hint: 'Caption IG/TikTok + hashtag', temp: 1.0 },
  { id: 'nama', label: 'Ide Nama', icon: 'bulb', hint: 'Nama brand/produk + maknanya', temp: 1.1 },
  { id: 'rilis', label: 'Catatan Rilis', icon: 'rocket', hint: 'Changelog / release notes rapi', temp: 0.5 },
  { id: 'iklan', label: 'Copy Iklan', icon: 'mega', hint: 'Hook, body, dan CTA yang menjual', temp: 0.9 },
  { id: 'email', label: 'Email & Pengumuman', icon: 'mail', hint: 'Email resmi + versi singkat WA', temp: 0.6 },
  { id: 'ide', label: 'Brainstorming', icon: 'brain', hint: 'Daftar ide + langkah eksekusi', temp: 1.0 },
  { id: 'script', label: 'Script Video', icon: 'play', hint: 'Naskah YouTube/TikTok/Reels', temp: 0.95, max: 3072 },
  { id: 'gambar', label: 'Prompt Gambar', icon: 'image', hint: 'Prompt Midjourney/SDXL/Flux', temp: 0.9 },
  { id: 'kalender', label: 'Kalender Konten', icon: 'cal', hint: 'Jadwal konten 7–30 hari', temp: 0.95, max: 3072 },
  { id: 'terjemah', label: 'Terjemah & Parafrase', icon: 'lang', hint: 'Terjemahan natural + 3 parafrase', temp: 0.5 },
  { id: 'produk', label: 'Deskripsi Produk', icon: 'bag', hint: 'Judul, bullet, SEO toko online', temp: 0.8 },
  { id: 'thread', label: 'Thread X / Twitter', icon: 'forum', hint: 'Rangkaian tweet yang enak dibaca', temp: 0.95, max: 3072 },
  { id: 'seo', label: 'Riset Keyword & SEO', icon: 'search', hint: 'Keyword, meta, outline artikel', temp: 0.7, max: 3072 },
  { id: 'cs', label: 'Balas Chat Pembeli', icon: 'support', hint: 'Balasan CS ramah & solutif', temp: 0.6 },
  { id: 'custom', label: 'Prompt Bebas', icon: 'spark', hint: 'Tulis instruksi apa saja', temp: 0.8, max: 4096 },
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
  { id: 'profesional', label: 'Profesional', instruction: 'profesional, jelas, dan dapat dipercaya' },
  { id: 'santai', label: 'Santai', instruction: 'santai, akrab, dan mengalir seperti ngobrol' },
  { id: 'persuasif', label: 'Persuasif', instruction: 'persuasif, memancing rasa penasaran, dan mendorong aksi' },
  { id: 'lucu', label: 'Lucu', instruction: 'lucu, jenaka, dan menghibur tanpa berlebihan' },
  { id: 'formal', label: 'Formal / Akademik', instruction: 'formal, baku, dan terstruktur seperti dokumen resmi' },
  { id: 'inspiratif', label: 'Inspiratif', instruction: 'inspiratif, hangat, dan memotivasi' },
];

export const LENGTHS = [
  { id: 'singkat', label: 'Singkat', instruction: 'sangat ringkas, maksimal sekitar 120 kata' },
  { id: 'sedang', label: 'Sedang', instruction: 'proporsional, sekitar 250-400 kata' },
  { id: 'panjang', label: 'Panjang', instruction: 'mendalam dan lengkap, 700 kata atau lebih bila perlu' },
];

export const MODELS = [
  { id: 'llama-3.3-70b-versatile', label: 'Llama 3.3 70B' },
  { id: 'openai/gpt-oss-120b', label: 'GPT-OSS 120B' },
  { id: 'openai/gpt-oss-20b', label: 'GPT-OSS 20B' },
  { id: 'meta-llama/llama-4-maverick-17b-128e-instruct', label: 'Llama 4 Maverick' },
  { id: 'meta-llama/llama-4-scout-17b-16e-instruct', label: 'Llama 4 Scout' },
  { id: 'qwen/qwen3-32b', label: 'Qwen3 32B' },
  { id: 'moonshotai/kimi-k2-instruct-0905', label: 'Kimi K2' },
  { id: 'llama-3.1-8b-instant', label: 'Llama 3.1 8B Instant' },
];
