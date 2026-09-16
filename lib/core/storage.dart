import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_item.dart';
import '../models/profile.dart';
import '../models/settings.dart';
import 'stats.dart';

/// Penyimpanan lokal sederhana (SharedPreferences).
class StorageService {
  SharedPreferences? _prefs;

  static const String _kSettings = 'settings';
  static const String _kHistory = 'history';
  static const String _kHidePopup = 'hide_channel_popup';
  static const String _kLaunchCount = 'launch_count';
  static const String _kStats = 'usage_stats';
  static const String _kRotation = 'auto_rotation_index';
  static const String _kProfile = 'user_profile';
  static const String _kDraft = 'draft_brief';

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

  /// Pengguna mencentang "jangan tampilkan lagi" di popup saluran WA.
  bool loadHideChannelPopup() => _prefs?.getBool(_kHidePopup) ?? false;

  Future<void> setHideChannelPopup(bool value) async {
    await _prefs?.setBool(_kHidePopup, value);
  }

  int loadLaunchCount() => _prefs?.getInt(_kLaunchCount) ?? 0;

  Future<void> setLaunchCount(int value) async {
    await _prefs?.setInt(_kLaunchCount, value);
  }

  // ── Statistik pemakaian ────────────────────────────────────────────────
  UsageStats loadStats() {
    final raw = _prefs?.getString(_kStats);
    if (raw == null || raw.isEmpty) return const UsageStats();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UsageStats.fromJson(decoded);
      }
    } catch (_) {
      // data rusak → mulai dari nol
    }
    return const UsageStats();
  }

  Future<void> saveStats(UsageStats stats) async {
    await _prefs?.setString(_kStats, jsonEncode(stats.toJson()));
  }

  Future<void> resetStats() async {
    await _prefs?.remove(_kStats);
  }

  // ── Rotasi model Auto ─────────────────────────────────────────────────
  int loadRotationIndex() => _prefs?.getInt(_kRotation) ?? 0;

  Future<void> setRotationIndex(int value) async {
    await _prefs?.setInt(_kRotation, value);
  }

  UserProfile? loadProfile() {
    final raw = _prefs?.getString(_kProfile);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserProfile.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveProfile(UserProfile? profile) async {
    if (profile == null) {
      await _prefs?.remove(_kProfile);
      return;
    }
    await _prefs?.setString(_kProfile, jsonEncode(profile.toJson()));
  }

  DraftBrief loadDraft() {
    final raw = _prefs?.getString(_kDraft);
    if (raw == null || raw.isEmpty) return const DraftBrief();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return DraftBrief.fromJson(decoded);
      }
    } catch (_) {}
    return const DraftBrief();
  }

  Future<void> saveDraft(DraftBrief draft) async {
    await _prefs?.setString(_kDraft, jsonEncode(draft.toJson()));
  }
}
