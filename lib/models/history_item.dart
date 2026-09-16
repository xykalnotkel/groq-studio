import 'dart:convert';

/// Satu hasil generate yang tersimpan di riwayat.
class HistoryItem {
  HistoryItem({
    required this.id,
    required this.modeId,
    required this.modeLabel,
    required this.brief,
    required this.extra,
    required this.output,
    required this.model,
    required this.createdAt,
    this.favorite = false,
  });

  final String id;
  final String modeId;
  final String modeLabel;
  final String brief;
  final String extra;
  final String output;
  final String model;
  final DateTime createdAt;
  final bool favorite;

  HistoryItem copyWith({String? output, bool? favorite, String? model}) {
    return HistoryItem(
      id: id,
      modeId: modeId,
      modeLabel: modeLabel,
      brief: brief,
      extra: extra,
      output: output ?? this.output,
      model: model ?? this.model,
      createdAt: createdAt,
      favorite: favorite ?? this.favorite,
    );
  }

  String get title {
    final trimmed = brief.trim();
    if (trimmed.isEmpty) return modeLabel;
    if (trimmed.length <= 60) return trimmed;
    return '${trimmed.substring(0, 60)}…';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'modeId': modeId,
    'modeLabel': modeLabel,
    'brief': brief,
    'extra': extra,
    'output': output,
    'model': model,
    'createdAt': createdAt.toIso8601String(),
    'favorite': favorite,
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    id: (json['id'] as String?) ?? '',
    modeId: (json['modeId'] as String?) ?? 'custom',
    modeLabel: (json['modeLabel'] as String?) ?? 'Prompt Bebas',
    brief: (json['brief'] as String?) ?? '',
    extra: (json['extra'] as String?) ?? '',
    output: (json['output'] as String?) ?? '',
    model: (json['model'] as String?) ?? '',
    createdAt:
        DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
        DateTime.now(),
    favorite: (json['favorite'] as bool?) ?? false,
  );

  static List<HistoryItem> decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <HistoryItem>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(HistoryItem.fromJson)
          .toList(growable: false);
    } catch (_) {
      return <HistoryItem>[];
    }
  }

  static String encodeList(List<HistoryItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList(growable: false));
}
