/// Konstanta & metadata aplikasi.
library;

/// API key yang di-inject saat build (GitHub Actions / CI).
///
/// Contoh:
/// ```bash
/// flutter build apk --release --obfuscate --split-debug-info=build/symbols \
///   --dart-define=GROQ_API_KEY=gsk_xxx
/// ```
/// Nilai ini dipakai hanya jika pengguna belum menyimpan key sendiri
/// lewat menu Setelan di dalam aplikasi.
const String kEnvApiKey = String.fromEnvironment(
  'GROQ_API_KEY',
  defaultValue: '',
);

class AppInfo {
  AppInfo._();

  static const String name = 'XyStudio AI';
  static const String tagline = 'Tulis apa saja, jadi cepat';
  static const String version = '2.0.0';

  /// Credit pembuat — tampil di splash screen & halaman Tentang.
  static const String brand = 'XyVerse';
  static const String credit = 'Built in XyVerse';

  static const String keysUrl = 'https://console.groq.com/keys';
  static const String docsUrl = 'https://console.groq.com/docs/models';
  static const String githubUrl = 'https://github.com/xykalnotkel/groq-studio';

  // ── Komunitas & bantuan ──────────────────────────────────────────────
  static const String waChannelUrl =
      'https://whatsapp.com/channel/0029VbB7nwuJZg3ym6UQ4Z1L';
  static const String waChannelName = 'Saluran WA XyVerse';
  static const String bugReportPhone = '6283116632566';
  static const String bugReportMessage =
      'Halo XyVerse! Saya mau lapor bug di XyStudio AI:%0A%0A'
      '• Perangkat / HP:%0A• Versi aplikasi:%0A• Mode yang dipakai:%0A'
      '• Cerita singkat:%0A• Screenshot (boleh dilampirkan terpisah)';
  static const String bugReportUrl =
      'https://wa.me/$bugReportPhone?text=$bugReportMessage';
}

/// Informasi model Groq.
class GroqModelInfo {
  const GroqModelInfo({
    required this.id,
    required this.label,
    required this.note,
    this.contextWindow = 0,
  });

  final String id;
  final String label;
  final String note;
  final int contextWindow;

  factory GroqModelInfo.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    return GroqModelInfo(
      id: id,
      label: _prettyName(id),
      note: (json['owned_by'] ?? 'Groq').toString(),
      contextWindow: (json['context_window'] as num?)?.toInt() ?? 0,
    );
  }

  /// fallback agar daftar offline tetap rapi kalau API /models gagal.
  static const List<GroqModelInfo> fallback = <GroqModelInfo>[
    GroqModelInfo(
      id: 'llama-3.3-70b-versatile',
      label: 'Llama 3.3 70B',
      note: 'Paling seimbang — andalan untuk nulis',
      contextWindow: 131072,
    ),
    GroqModelInfo(
      id: 'openai/gpt-oss-120b',
      label: 'GPT-OSS 120B',
      note: 'Paling kuat, output paling rapi',
      contextWindow: 131072,
    ),
    GroqModelInfo(
      id: 'openai/gpt-oss-20b',
      label: 'GPT-OSS 20B',
      note: 'Kuat tapi tetap cepat',
      contextWindow: 131072,
    ),
    GroqModelInfo(
      id: 'meta-llama/llama-4-maverick-17b-128e-instruct',
      label: 'Llama 4 Maverick',
      note: 'Kreatif, bagus untuk ide & judul',
      contextWindow: 131072,
    ),
    GroqModelInfo(
      id: 'meta-llama/llama-4-scout-17b-16e-instruct',
      label: 'Llama 4 Scout',
      note: 'Cepat & efisien',
      contextWindow: 131072,
    ),
    GroqModelInfo(
      id: 'qwen/qwen3-32b',
      label: 'Qwen3 32B',
      note: 'Bagus untuk bahasa & logika',
      contextWindow: 131072,
    ),
    GroqModelInfo(
      id: 'moonshotai/kimi-k2-instruct-0905',
      label: 'Kimi K2',
      note: 'Jagoan teks panjang',
      contextWindow: 131072,
    ),
    GroqModelInfo(
      id: 'llama-3.1-8b-instant',
      label: 'Llama 3.1 8B Instant',
      note: 'Paling ngebut, hemat kuota',
      contextWindow: 131072,
    ),
  ];

  static String _prettyName(String id) {
    final tail = id.contains('/') ? id.split('/').last : id;
    return tail
        .replaceAll('-instruct', '')
        .replaceAll('-versatile', '')
        .replaceAll('-instant', '')
        .replaceAll('-0905', '')
        .replaceAll('meta-llama/', '')
        .replaceAll('moonshotai/', '');
  }
}

/// Daftar id model yang tidak dipakai untuk chat teks (audio / guard / dll).
const List<String> kNonChatModelFilters = <String>[
  'whisper',
  'guard',
  'tts',
  'allam',
  'prompt-guard',
];
