import 'text_utils.dart';

/// Statistik pemakaian aplikasi: dihitung dari hasil generate yang sukses.
class UsageStats {
  const UsageStats({
    this.totalGenerates = 0,
    this.totalWords = 0,
    this.totalChars = 0,
    this.modeCounts = const <String, int>{},
    this.dailyCounts = const <String, int>{},
    this.lastUsed,
  });

  final int totalGenerates;
  final int totalWords;
  final int totalChars;

  /// modeId -> berapa kali dipakai.
  final Map<String, int> modeCounts;

  /// 'yyyy-MM-dd' -> berapa kali generate di hari itu.
  final Map<String, int> dailyCounts;

  final DateTime? lastUsed;

  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  UsageStats record({
    required String modeId,
    required String output,
    DateTime? at,
  }) {
    final when = at ?? DateTime.now();
    final key = dayKey(when);
    return UsageStats(
      totalGenerates: totalGenerates + 1,
      totalWords: totalWords + countWords(output),
      totalChars: totalChars + output.length,
      modeCounts: <String, int>{
        ...modeCounts,
        modeId: (modeCounts[modeId] ?? 0) + 1,
      },
      dailyCounts: <String, int>{
        ...dailyCounts,
        key: (dailyCounts[key] ?? 0) + 1,
      },
      lastUsed: when,
    );
  }

  /// Mode yang paling sering dipakai (null kalau belum ada data).
  String? get favoriteModeId {
    if (modeCounts.isEmpty) return null;
    var best = modeCounts.entries.first;
    for (final entry in modeCounts.entries) {
      if (entry.value > best.value) best = entry;
    }
    return best.key;
  }

  /// Streak harian: berapa hari beruntun (sampai hari ini, atau sampai
  /// kemarin kalau hari ini belum generate).
  int get dailyStreak {
    if (dailyCounts.isEmpty) return 0;
    var cursor = DateTime.now();
    if (!dailyCounts.containsKey(dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!dailyCounts.containsKey(dayKey(cursor))) return 0;
    }
    var streak = 0;
    while (dailyCounts.containsKey(dayKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Jumlah generate per hari untuk [days] hari terakhir (urutan lama → baru).
  List<UsageDayPoint> lastDays(int days) {
    final now = DateTime.now();
    return List<UsageDayPoint>.generate(days, (index) {
      final date = now.subtract(Duration(days: days - 1 - index));
      final key = dayKey(date);
      return UsageDayPoint(date: date, count: dailyCounts[key] ?? 0);
    }, growable: false);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'totalGenerates': totalGenerates,
    'totalWords': totalWords,
    'totalChars': totalChars,
    'modeCounts': modeCounts,
    'dailyCounts': dailyCounts,
    'lastUsed': lastUsed?.toIso8601String(),
  };

  factory UsageStats.fromJson(Map<String, dynamic> json) => UsageStats(
    totalGenerates: (json['totalGenerates'] as num?)?.toInt() ?? 0,
    totalWords: (json['totalWords'] as num?)?.toInt() ?? 0,
    totalChars: (json['totalChars'] as num?)?.toInt() ?? 0,
    modeCounts: <String, int>{
      for (final entry
          in (json['modeCounts'] as Map<String, dynamic>? ??
                  <String, dynamic>{})
              .entries)
        entry.key: (entry.value as num?)?.toInt() ?? 0,
    },
    dailyCounts: <String, int>{
      for (final entry
          in (json['dailyCounts'] as Map<String, dynamic>? ??
                  <String, dynamic>{})
              .entries)
        entry.key: (entry.value as num?)?.toInt() ?? 0,
    },
    lastUsed: DateTime.tryParse((json['lastUsed'] as String?) ?? ''),
  );
}

class UsageDayPoint {
  const UsageDayPoint({required this.date, required this.count});

  final DateTime date;
  final int count;

  String get shortLabel => const <String>[
    'Min',
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
  ][date.weekday % 7];
}
