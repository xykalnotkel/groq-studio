import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_item.dart';
import '../models/settings.dart';

/// Penyimpanan lokal sederhana (SharedPreferences).
class StorageService {
  SharedPreferences? _prefs;

  static const String _kSettings = 'settings';
  static const String _kHistory = 'history';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Settings loadSettings() {
    final raw = _prefs?.getString(_kSettings);
    if (raw == null || raw.isEmpty) return const Settings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return Settings.fromJson(decoded);
      }
    } catch (_) {
      // fallback ke pengaturan bawaan
    }
    return const Settings();
  }

  Future<void> saveSettings(Settings settings) async {
    await _prefs?.setString(_kSettings, jsonEncode(settings.toJson()));
  }

  List<HistoryItem> loadHistory() {
    final raw = _prefs?.getString(_kHistory);
    if (raw == null || raw.isEmpty) return <HistoryItem>[];
    return HistoryItem.decodeList(raw);
  }

  Future<void> saveHistory(List<HistoryItem> items) async {
    await _prefs?.setString(_kHistory, HistoryItem.encodeList(items));
  }
}
