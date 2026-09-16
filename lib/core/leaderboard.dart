import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/profile.dart';

/// Entri papan peringkat penghabis token.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.rank,
    required this.name,
    required this.tokens,
    required this.weekTokens,
    required this.generates,
  });

  final String id;
  final int rank;
  final String name;
  final int tokens;
  final int weekTokens;
  final int generates;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: (json['id'] as String?) ?? '',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? 'Anonim',
      tokens: (json['tokens'] as num?)?.toInt() ?? 0,
      weekTokens: (json['weekTokens'] as num?)?.toInt() ?? 0,
      generates: (json['generates'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardSnapshot {
  const LeaderboardSnapshot({
    required this.all,
    required this.weekly,
    this.me,
    this.meWeek,
    this.total = 0,
    this.week = '',
  });

  final List<LeaderboardEntry> all;
  final List<LeaderboardEntry> weekly;
  final LeaderboardEntry? me;
  final LeaderboardEntry? meWeek;
  final int total;
  final String week;

  static const empty = LeaderboardSnapshot(
    all: <LeaderboardEntry>[],
    weekly: <LeaderboardEntry>[],
  );
}

/// Klien papan peringkat (API Vercel).
class LeaderboardClient {
  LeaderboardClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _base = baseUrl ?? kLeaderboardUrl;

  static const String kLeaderboardUrl =
      'https://xystudio.my.id/api/leaderboard';

  final http.Client _client;
  final String _base;

  Future<LeaderboardSnapshot> fetch({String? userId}) async {
    final uri = Uri.parse(_base).replace(
      queryParameters: userId == null || userId.isEmpty
          ? null
          : <String, String>{'me': userId},
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw LeaderboardException(_message(response.statusCode, response.body));
    }
    return _parse(response.body);
  }

  Future<LeaderboardSnapshot> submit({
    required UserProfile profile,
    required String action,
    int tokens = 0,
    int generates = 0,
  }) async {
    final response = await _client
        .post(
          Uri.parse(_base),
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'action': action,
            'email': profile.email,
            'name': profile.name,
            'pin': profile.pin,
            'tokens': tokens,
            'generates': generates,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LeaderboardException(_message(response.statusCode, response.body));
    }
    return _parse(response.body);
  }

  static LeaderboardSnapshot _parse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return LeaderboardSnapshot.empty;
    List<LeaderboardEntry> read(String key) {
      final list = decoded[key];
      if (list is! List) return const <LeaderboardEntry>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(LeaderboardEntry.fromJson)
          .toList(growable: false);
    }

    LeaderboardEntry? one(String key) {
      final value = decoded[key];
      if (value is Map<String, dynamic>) {
        return LeaderboardEntry.fromJson(value);
      }
      return null;
    }

    return LeaderboardSnapshot(
      all: read('all'),
      weekly: read('weekly'),
      me: one('me'),
      meWeek: one('meWeek'),
      total: (decoded['total'] as num?)?.toInt() ?? 0,
      week: (decoded['week'] as String?) ?? '',
    );
  }

  static String _message(int code, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {}
    if (code == 401) return 'Email atau PIN salah.';
    if (code == 409) return 'Email ini sudah terdaftar. Masuk saja.';
    if (code == 503) return 'Papan sedang disiapkan.';
    return 'Tidak bisa menghubungi papan peringkat.';
  }
}

class LeaderboardException implements Exception {
  LeaderboardException(this.message);

  final String message;

  @override
  String toString() => message;
}

String formatTokens(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)} jt';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)} rb';
  }
  return '$value';
}

String initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  String first(String value) =>
      value.isEmpty ? '' : value.substring(0, 1).toUpperCase();
  if (parts.length == 1) return first(parts.first);
  final a = first(parts.first);
  final b = first(parts.last);
  if (a.isEmpty) return '?';
  return '$a$b';
}
