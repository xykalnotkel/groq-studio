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
  static const String version = '3.0.0';

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

/// Id pseudo-model: aplikasi merotasi model otomatis tiap generate dan
/// pindah sendiri ke model lain saat terkena 429 / 5xx / error.
const String kAutoModelId = 'auto';
const String kAutoModelLabel = 'Auto (muter)';

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

  /// Daftar fallback — hanya model chat yang HIDUP per September 2026
  /// (Llama 3.1/3.3, Llama 4 Scout, dan Qwen3 32B sudah dimatikan Groq).
  static const List<GroqModelInfo> fallback = <GroqModelInfo>[
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
      id: 'qwen/qwen3.8-27b',
      label: 'Qwen3.8 27B',
      note: 'Seimbang untuk bahasa & logika',
      contextWindow: 131072,
    ),
    GroqModelInfo(
      id: 'allam-2-7b',
      label: 'Allam 2 7B',
      note: 'Ringan & hemat, konteks kecil',
      contextWindow: 4096,
    ),
  ];

  static String _prettyName(String id) {
    final tail = id.contains('/') ? id.split('/').last : id;
    return tail
        .replaceAll('-instruct', '')
        .replaceAll('-versatile', '')
        .replaceAll('-instant', '')
        .replaceAll('openai/', '')
        .replaceAll('meta-llama/', '')
        .replaceAll('moonshotai/', '')
        .replaceAll('qwen/', '');
  }
}

/// Potongan id model yang TIDAK dipakai untuk chat teks:
/// audio (whisper/orpheus/tts), penjaga keamanan (guard/safeguard/
/// prompt-guard), dan model Compound (menolak payload aplikasi — HTTP 413).
const List<String> kNonChatModelFilters = <String>[
  'whisper',
  'orpheus',
  'guard',
  'safeguard',
  'tts',
  'compound',
  'playai',
  'distil',
];

/// Model TTS Groq untuk keluaran bahasa Inggris.
const String kOrpheusEnglishModel = 'canopylabs/orpheus-v1-english';
