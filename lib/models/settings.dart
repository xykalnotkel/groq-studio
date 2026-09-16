import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Bahasa keluaran hasil generate.
class OutputLanguage {
  const OutputLanguage(this.code, this.label);

  final String code; // 'id', 'en', ...
  final String label;

  static const OutputLanguage indonesian = OutputLanguage(
    'id',
    'Bahasa Indonesia',
  );
  static const OutputLanguage english = OutputLanguage('en', 'English');
  static const OutputLanguage malay = OutputLanguage('ms', 'Bahasa Melayu');
  static const OutputLanguage arabic = OutputLanguage('ar', 'العربية');
  static const OutputLanguage japanese = OutputLanguage('ja', '日本語');
  static const OutputLanguage chinese = OutputLanguage('zh', '中文');
  static const OutputLanguage spanish = OutputLanguage('es', 'Español');

  static const List<OutputLanguage> values = <OutputLanguage>[
    indonesian,
    english,
    malay,
    japanese,
    chinese,
    arabic,
    spanish,
  ];

  static OutputLanguage fromCode(String code) =>
      values.firstWhere((e) => e.code == code, orElse: () => indonesian);

  @override
  bool operator ==(Object other) =>
      other is OutputLanguage && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Gaya / nada penulisan.
class ToneOption {
  const ToneOption(this.id, this.label, this.instruction);

  final String id;
  final String label;
  final String instruction;

  static const ToneOption natural = ToneOption(
    'natural',
    'Natural',
    'natural, seperti ditulis manusia sungguhan, tidak kaku dan tidak '
        'berlebihan',
  );
  static const ToneOption profesional = ToneOption(
    'profesional',
    'Profesional',
    'profesional, jelas, dan dapat dipercaya',
  );
  static const ToneOption padatTajam = ToneOption(
    'padat',
    'Padat & Tajam',
    'padat, langsung ke inti, tanpa kata mubazir; setiap kalimat harus '
        'membawa informasi',
  );
  static const ToneOption bercerita = ToneOption(
    'bercerita',
    'Bercerita',
    'bercerita (storytelling): ada alur, tokoh atau situasi, dan emosi yang '
        'mengalir',
  );
  static const ToneOption elegan = ToneOption(
    'elegan',
    'Elegan',
    'elegan, tenang, dan berkelas; kalimat tertata dengan diksi pilihan',
  );
  static const ToneOption santai = ToneOption(
    'santai',
    'Santai',
    'santai, akrab, dan mengalir seperti ngobrol (boleh pakai "kamu")',
  );
  static const ToneOption persuasif = ToneOption(
    'persuasif',
    'Persuasif',
    'persuasif, memancing rasa penasaran, dan mendorong aksi',
  );
  static const ToneOption informatif = ToneOption(
    'informatif',
    'Informatif',
    'informatif dan objektif: utamakan fakta, data, dan penjelasan runtut',
  );
  static const ToneOption puitis = ToneOption(
    'puitis',
    'Puitis',
    'puitis dan penuh citra rasa; ritme kalimat dijaga tanpa jadi berlebihan',
  );
  static const ToneOption lucu = ToneOption(
    'lucu',
    'Lucu',
    'lucu, jenaka, dan menghibur tanpa berlebihan',
  );
  static const ToneOption formal = ToneOption(
    'formal',
    'Formal / Akademik',
    'formal, baku, dan terstruktur seperti dokumen resmi',
  );
  static const ToneOption inspiratif = ToneOption(
    'inspiratif',
    'Inspiratif',
    'inspiratif, hangat, dan memotivasi',
  );

  static const List<ToneOption> values = <ToneOption>[
    natural,
    profesional,
    padatTajam,
    bercerita,
    elegan,
    santai,
    persuasif,
    informatif,
    puitis,
    lucu,
    formal,
    inspiratif,
  ];

  static ToneOption fromId(String id) =>
      values.firstWhere((e) => e.id == id, orElse: () => natural);

  @override
  bool operator ==(Object other) => other is ToneOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Panjang hasil.
class LengthOption {
  const LengthOption(this.id, this.label, this.instruction);

  final String id;
  final String label;
  final String instruction;

  static const LengthOption singkat = LengthOption(
    'singkat',
    'Singkat',
    'sangat ringkas, maksimal sekitar 120 kata',
  );
  static const LengthOption sedang = LengthOption(
    'sedang',
    'Sedang',
    'proporsional, sekitar 250-400 kata',
  );
  static const LengthOption panjang = LengthOption(
    'panjang',
    'Panjang',
    'mendalam dan lengkap, 700 kata atau lebih bila perlu',
  );

  static const List<LengthOption> values = <LengthOption>[
    singkat,
    sedang,
    panjang,
  ];

  static LengthOption fromId(String id) =>
      values.firstWhere((e) => e.id == id, orElse: () => sedang);

  @override
  bool operator ==(Object other) => other is LengthOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Usaha penalaran untuk model GPT-OSS (reasoning_effort).
class ReasoningOption {
  const ReasoningOption(this.id, this.label);

  final String id; // low / medium / high
  final String label;

  static const List<ReasoningOption> values = <ReasoningOption>[
    ReasoningOption('low', 'Rendah (cepat)'),
    ReasoningOption('medium', 'Sedang (seimbang)'),
    ReasoningOption('high', 'Tinggi (mendalam)'),
  ];

  static ReasoningOption fromId(String id) =>
      values.firstWhere((e) => e.id == id, orElse: () => values[1]);

  @override
  bool operator ==(Object other) => other is ReasoningOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Seluruh preferensi yang bisa diubah pengguna.
class Settings {
  const Settings({
    this.apiKey = '',
    this.model = kAutoModelId,
    this.language = OutputLanguage.indonesian,
    this.tone = ToneOption.natural,
    this.length = LengthOption.sedang,
    this.temperature = 0.8,
    this.streaming = true,
    this.themeMode = ThemeMode.dark,
    this.typewriter = true,
    this.typewriterSpeed = 5,
    this.reasoning = 'medium',
    this.ttsPitch = 1.0,
    this.ttsRate = 1.0,
  });

  /// 'auto' = rotasi otomatis tiap generate + pindah model saat error.
  static const String defaultModel = kAutoModelId;

  final String apiKey;
  final String model;
  final OutputLanguage language;
  final ToneOption tone;
  final LengthOption length;
  final double temperature;
  final bool streaming;
  final ThemeMode themeMode;

  /// Animasi output huruf demi huruf.
  final bool typewriter;

  /// Kecepatan animasi 1 (pelan) – 10 (ngebut).
  final int typewriterSpeed;

  /// reasoning_effort untuk GPT-OSS.
  final String reasoning;

  /// Default nada (pitch) suara untuk tombol Dengarkan (0.5 – 2.0).
  final double ttsPitch;

  /// Default kecepatan bicara untuk tombol Dengarkan (0.5 – 2.0).
  final double ttsRate;

  Settings copyWith({
    String? apiKey,
    String? model,
    OutputLanguage? language,
    ToneOption? tone,
    LengthOption? length,
    double? temperature,
    bool? streaming,
    ThemeMode? themeMode,
    bool? typewriter,
    int? typewriterSpeed,
    String? reasoning,
    double? ttsPitch,
    double? ttsRate,
  }) {
    return Settings(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      language: language ?? this.language,
      tone: tone ?? this.tone,
      length: length ?? this.length,
      temperature: temperature ?? this.temperature,
      streaming: streaming ?? this.streaming,
      themeMode: themeMode ?? this.themeMode,
      typewriter: typewriter ?? this.typewriter,
      typewriterSpeed: typewriterSpeed ?? this.typewriterSpeed,
      reasoning: reasoning ?? this.reasoning,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      ttsRate: ttsRate ?? this.ttsRate,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'apiKey': apiKey,
    'model': model,
    'language': language.code,
    'tone': tone.id,
    'length': length.id,
    'temperature': temperature,
    'streaming': streaming,
    'themeMode': themeMode.name,
    'typewriter': typewriter,
    'typewriterSpeed': typewriterSpeed,
    'reasoning': reasoning,
    'ttsPitch': ttsPitch,
    'ttsRate': ttsRate,
  };

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
    apiKey: (json['apiKey'] as String?) ?? '',
    model: (json['model'] as String?) ?? defaultModel,
    language: OutputLanguage.fromCode((json['language'] as String?) ?? 'id'),
    tone: ToneOption.fromId((json['tone'] as String?) ?? 'natural'),
    length: LengthOption.fromId((json['length'] as String?) ?? 'sedang'),
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0.8,
    streaming: (json['streaming'] as bool?) ?? true,
    themeMode: ThemeMode.values.firstWhere(
      (m) => m.name == json['themeMode'],
      orElse: () => ThemeMode.dark,
    ),
    typewriter: (json['typewriter'] as bool?) ?? true,
    typewriterSpeed: ((json['typewriterSpeed'] as num?)?.toInt() ?? 5).clamp(
      1,
      10,
    ),
    reasoning: (json['reasoning'] as String?) ?? 'medium',
    ttsPitch: ((json['ttsPitch'] as num?)?.toDouble() ?? 1.0).clamp(0.5, 2.0),
    ttsRate: ((json['ttsRate'] as num?)?.toDouble() ?? 1.0).clamp(0.5, 2.0),
  );
}
