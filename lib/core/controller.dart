import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/generation_mode.dart';
import '../models/history_item.dart';
import '../models/settings.dart';
import 'constants.dart';
import 'groq_client.dart';
import 'prompt_builder.dart';
import 'speech.dart';
import 'stats.dart';
import 'storage.dart';
import 'text_utils.dart';
import 'web_research.dart';

enum GenerationStatus { idle, loading, streaming, success, error }

/// Permintaan terakhir, supaya tombol "ulangi" bisa dipakai.
class _LastRequest {
  _LastRequest({
    required this.mode,
    required this.brief,
    required this.extra,
    required this.engine,
  });

  final GenerationMode mode;
  final String brief;
  final String extra;
  final String? engine;
}

/// State aplikasi: pengaturan, riwayat, statistik, dan proses generate.
class AppController extends ChangeNotifier {
  AppController(this._storage, [this._testing = false]);

  final StorageService _storage;
  final bool _testing;

  Settings _settings = const Settings();
  List<HistoryItem> _history = <HistoryItem>[];
  UsageStats _stats = const UsageStats();
  List<GroqModelInfo> _models = GroqModelInfo.fallback;
  GenerationStatus _status = GenerationStatus.idle;
  String _rawOutput = '';
  String? _errorMessage;
  String? _statusMessage;
  String? _answeredBy;
  GroqClient? _client;
  WebResearch? _research;
  _LastRequest? _lastRequest;
  bool _loadingModels = false;
  String? _modelsError;
  Duration _elapsed = Duration.zero;
  int _launchCount = 0;
  bool _hideChannelPopup = false;
  DateTime? _startedAt;
  Timer? _ticker;
  int _genToken = 0;
  int _autoIndex = 0;

  static const int _historyLimit = 200;

  late final SpeechService speech = SpeechService(
    () => _clientFor(apiKey),
    _testing,
  );

  // ── Getter ────────────────────────────────────────────────────────────
  Settings get settings => _settings;
  List<HistoryItem> get history => List.unmodifiable(_history);
  List<HistoryItem> get favorites =>
      _history.where((item) => item.favorite).toList(growable: false);
  List<GroqModelInfo> get models => List.unmodifiable(_models);
  GenerationStatus get status => _status;
  UsageStats get stats => _stats;

  /// Keluaran yang sudah dibersihkan dari emoji (disaring di kode).
  String get output => stripEmoji(_rawOutput);
  String? get errorMessage => _errorMessage;

  /// Pesan progres ("Mencari sumber…", "Menulis dengan …").
  String? get statusMessage => _statusMessage;

  /// Model yang benar-benar menjawab terakhir kali (untuk badge).
  String? get answeredBy => _answeredBy;
  String? get answeredByLabel {
    final id = _answeredBy;
    if (id == null) return null;
    final info = _models.where((m) => m.id == id).toList();
    return info.isEmpty ? id : info.first.label;
  }

  Duration get elapsed => _elapsed;
  bool get isBusy =>
      _status == GenerationStatus.loading ||
      _status == GenerationStatus.streaming;
  bool get isLoadingModels => _loadingModels;
  String? get modelsError => _modelsError;
  bool get hideChannelPopup => _hideChannelPopup;

  /// Key yang dipakai: punya pengguna, atau hasil inject saat build.
  String get apiKey =>
      _settings.apiKey.trim().isNotEmpty ? _settings.apiKey.trim() : kEnvApiKey;
  bool get hasApiKey => apiKey.isNotEmpty;

  GenerationMode get lastMode =>
      _lastRequest?.mode ?? GenerationMode.values.first;

  bool get isAutoModel => _settings.model == kAutoModelId;

  // ── Inisialisasi ──────────────────────────────────────────────────────
  Future<void> load() async {
    await _storage.init();
    _settings = _storage.loadSettings();
    _history = _storage.loadHistory();
    _stats = _storage.loadStats();
    _hideChannelPopup = _storage.loadHideChannelPopup();
    _autoIndex = _storage.loadRotationIndex();
    notifyListeners();
    if (hasApiKey) {
      unawaited(refreshModels());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _client?.close();
    _research?.close();
    super.dispose();
  }

  /// Dipanggil sekali setiap aplikasi dibuka.
  ///
  /// Popup ajakan gabung saluran WA tampil di kunjungan pertama, lalu
  /// setiap 4 kali buka — kecuali pengguna mencentang
  /// "jangan tampilkan lagi".
  Future<void> registerLaunch() async {
    _launchCount = _storage.loadLaunchCount() + 1;
    await _storage.setLaunchCount(_launchCount);
    _hideChannelPopup = _storage.loadHideChannelPopup();
    notifyListeners();
  }

  bool get shouldShowChannelPopup =>
      !_hideChannelPopup && (_launchCount <= 1 || _launchCount % 4 == 0);

  Future<void> setHideChannelPopup(bool value) async {
    _hideChannelPopup = value;
    notifyListeners();
    await _storage.setHideChannelPopup(value);
  }

  /// Untuk keperluan demo: paksa tampilkan popup lagi.
  Future<void> resetChannelPopup() async {
    await setHideChannelPopup(false);
    _launchCount = 0;
    await _storage.setLaunchCount(0);
    notifyListeners();
  }

  // ── Pengaturan ────────────────────────────────────────────────────────
  Future<void> updateSettings(Settings next) async {
    _settings = next;
    notifyListeners();
    await _storage.saveSettings(next);
    _resetClient();
  }

  void _resetClient() {
    _client?.close();
    _client = null;
  }

  GroqClient _clientFor(String key) => _client ??= GroqClient(apiKey: key);

  WebResearch get _researcher => _research ??= WebResearch();

  // ── Statistik ─────────────────────────────────────────────────────────
  Future<void> resetStats() async {
    _stats = const UsageStats();
    notifyListeners();
    await _storage.resetStats();
  }

  void _recordStats(String modeId) {
    final text = output;
    if (text.trim().isEmpty) return;
    _stats = _stats.record(modeId: modeId, output: text);
    unawaited(_storage.saveStats(_stats));
  }

  // ── Generate ──────────────────────────────────────────────────────────
  Future<void> generate({
    required GenerationMode mode,
    required String brief,
    String extra = '',
    String? engine,
  }) async {
    final trimmed = brief.trim();
    if (trimmed.isEmpty) {
      _fail(
        mode.kind == ModeKind.urlSummary
            ? 'Tempel dulu URL halamannya di atas ya.'
            : 'Tulis dulu brief-nya di atas ya.',
      );
      return;
    }
    if (!hasApiKey) {
      _fail('API key Groq belum ada. Buka tab Setelan lalu tempel key kamu.');
      return;
    }

    final token = ++_genToken;
    _lastRequest = _LastRequest(
      mode: mode,
      brief: trimmed,
      extra: extra,
      engine: engine,
    );

    _rawOutput = '';
    _errorMessage = null;
    _answeredBy = null;
    _status = GenerationStatus.loading;
    _elapsed = Duration.zero;
    _startedAt = DateTime.now();
    _startTicker();
    notifyListeners();

    // ── Pra-pemrosesan mode riset & URL ──────────────────────────────
    String? sourcesBlock;
    try {
      if (mode.kind == ModeKind.webResearch && !_testing) {
        _setStatusMessage('Mencari sumber di web…');
        final sources = await _researcher.research(trimmed);
        if (_genToken != token) return;
        _setStatusMessage('Membaca ${sources.length} halaman, lalu merangkum…');
        sourcesBlock = PromptBuilder.researchBlock(
          trimmed,
          sourcesToPromptBlock(sources),
        );
      } else if (mode.kind == ModeKind.urlSummary && !_testing) {
        final url = firstUrl(trimmed);
        if (url == null) {
          _fail('Tidak menemukan URL di teks kamu. Tempel link lengkapnya.');
          return;
        }
        _setStatusMessage('Membuka $url …');
        final text = await _researcher.fetchPageText(
          url.toString(),
          maxChars: 6000,
        );
        if (_genToken != token) return;
        _setStatusMessage('Menulis ringkasan…');
        sourcesBlock = PromptBuilder.urlBlock(url.toString(), '', text);
      }
    } on WebResearchException catch (error) {
      _fail(error.message);
      return;
    } catch (error) {
      _fail(_readable(error));
      return;
    }

    final prompt = PromptBuilder.build(
      mode: mode,
      settings: _settings,
      brief: trimmed,
      extra: extra,
      engine: engine,
      sourcesBlock: sourcesBlock,
    );
    final temperature = PromptBuilder.temperatureFor(mode, _settings);
    final maxTokens = PromptBuilder.maxTokensFor(mode);

    // ── Pilih model ────────────────────────────────────────────────────
    final candidates = isAutoModel
        ? (_models.isEmpty ? GroqModelInfo.fallback : _models)
        : <GroqModelInfo>[];
    final manualModel = _models.where((m) => m.id == _settings.model).toList();

    final attempts = isAutoModel
        ? List<GroqModelInfo>.generate(
            candidates.length,
            (i) => candidates[(_autoIndex + i) % candidates.length],
          )
        : (manualModel.isNotEmpty
              ? manualModel
              : <GroqModelInfo>[
                  GroqModelInfo(
                    id: _settings.model,
                    label: _settings.model,
                    note: '',
                  ),
                ]);

    final client = _clientFor(apiKey);

    for (var i = 0; i < attempts.length; i++) {
      if (_genToken != token) return;
      final model = attempts[i];

      if (isAutoModel) {
        _autoIndex = (_autoIndex + 1) % candidates.length;
        unawaited(_storage.setRotationIndex(_autoIndex));
      }

      _answeredBy = model.id;
      _setStatusMessage('Menulis dengan ${model.label}…');
      _status = _settings.streaming
          ? GenerationStatus.streaming
          : GenerationStatus.loading;
      notifyListeners();

      try {
        if (_settings.streaming) {
          await for (final delta in client.stream(
            model: model.id,
            system: prompt.system,
            prompt: prompt.user,
            temperature: temperature,
            maxTokens: maxTokens,
            reasoningEffort: _settings.reasoning,
            contextWindow: model.contextWindow,
          )) {
            if (_genToken != token) return;
            _rawOutput += delta;
            notifyListeners();
          }
        } else {
          final text = await client.complete(
            model: model.id,
            system: prompt.system,
            prompt: prompt.user,
            temperature: temperature,
            maxTokens: maxTokens,
            reasoningEffort: _settings.reasoning,
            contextWindow: model.contextWindow,
          );
          if (_genToken != token) return;
          _rawOutput = text;
        }
        _succeed(mode);
        return;
      } catch (error) {
        if (_genToken != token) return;
        final canSwitch =
            isAutoModel && i < attempts.length - 1 && _rawOutput.isEmpty;
        if (canSwitch) {
          final next = attempts[i + 1];
          _setStatusMessage(
            '${model.label} bermasalah — pindah otomatis ke ${next.label}…',
          );
          notifyListeners();
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        // Sudah ada hasil sebagian → simpan sebagai hasil.
        if (_rawOutput.trim().isNotEmpty) {
          _succeed(mode);
          return;
        }
        _fail(_readable(error));
        return;
      }
    }
  }

  /// Ulangi generate terakhir.
  Future<void> regenerate() async {
    final last = _lastRequest;
    if (last == null) return;
    await generate(
      mode: last.mode,
      brief: last.brief,
      extra: last.extra,
      engine: last.engine,
    );
  }

  void stop() {
    _genToken++;
    _stopTicker();
    if (_rawOutput.trim().isNotEmpty) {
      _status = GenerationStatus.success;
      _statusMessage = null;
      _saveToHistory();
    } else {
      _status = GenerationStatus.idle;
      _statusMessage = null;
    }
    notifyListeners();
  }

  void reset() {
    _genToken++;
    _stopTicker();
    _status = GenerationStatus.idle;
    _rawOutput = '';
    _errorMessage = null;
    _statusMessage = null;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  void _setStatusMessage(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final start = _startedAt;
      if (start == null) return;
      _elapsed = DateTime.now().difference(start);
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (_startedAt != null) {
      _elapsed = DateTime.now().difference(_startedAt!);
    }
  }

  void _succeed(GenerationMode mode) {
    _stopTicker();
    _status = GenerationStatus.success;
    _statusMessage = null;
    _saveToHistory();
    _recordStats(mode.id);
    notifyListeners();
  }

  void _fail(Object error) {
    _stopTicker();
    _genToken++;
    _status = GenerationStatus.error;
    _statusMessage = null;
    _errorMessage = error is GroqException ? error.message : error.toString();
    notifyListeners();
  }

  String _readable(Object error) {
    if (error is GroqException) return error.message;
    if (error is WebResearchException) return error.message;
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup')) {
      return 'Tidak ada koneksi internet. Cek jaringan kamu lalu coba lagi.';
    }
    if (text.contains('TimeoutException') || text.contains('timeout')) {
      return 'Groq lambat merespons. Coba lagi atau ganti model yang lebih cepat.';
    }
    return 'Terjadi kesalahan: $text';
  }

  void _saveToHistory() {
    final last = _lastRequest;
    if (last == null || _rawOutput.trim().isEmpty) return;

    // Hindari duplikat kalau hasilnya sama persis dengan yang terakhir.
    if (_history.isNotEmpty &&
        _history.first.output == output &&
        _history.first.brief == last.brief) {
      return;
    }

    final item = HistoryItem(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      modeId: last.mode.id,
      modeLabel: last.mode.label,
      brief: last.brief,
      extra: last.extra,
      output: output,
      model: _answeredBy ?? _settings.model,
      createdAt: DateTime.now(),
    );
    _history = <HistoryItem>[item, ..._history];
    if (_history.length > _historyLimit) {
      _history = _history.sublist(0, _historyLimit);
    }
    unawaited(_storage.saveHistory(_history));
  }

  // ── Riwayat ───────────────────────────────────────────────────────────
  Future<void> toggleFavorite(String id) async {
    _history = _history
        .map(
          (item) =>
              item.id == id ? item.copyWith(favorite: !item.favorite) : item,
        )
        .toList(growable: true);
    notifyListeners();
    await _storage.saveHistory(_history);
  }

  Future<void> deleteHistory(String id) async {
    _history = _history.where((item) => item.id != id).toList(growable: true);
    notifyListeners();
    await _storage.saveHistory(_history);
  }

  Future<void> clearHistory() async {
    _history = <HistoryItem>[];
    notifyListeners();
    await _storage.saveHistory(_history);
  }

  // ── Model ─────────────────────────────────────────────────────────────
  Future<void> refreshModels() async {
    if (!hasApiKey) {
      _models = GroqModelInfo.fallback;
      _modelsError = null;
      notifyListeners();
      return;
    }
    _loadingModels = true;
    _modelsError = null;
    notifyListeners();

    final client = _clientFor(apiKey);
    try {
      final fetched = await client.fetchModels();
      if (fetched.isNotEmpty) {
        _models = _sortModels(fetched);
      }
    } on GroqException catch (error) {
      _modelsError = error.message;
      if (_models.isEmpty) _models = GroqModelInfo.fallback;
    } catch (_) {
      _modelsError = 'Gagal memuat daftar model.';
      if (_models.isEmpty) _models = GroqModelInfo.fallback;
    } finally {
      _loadingModels = false;
      notifyListeners();
    }
  }

  /// Tes koneksi dengan key tertentu (dipakai menu Setelan).
  Future<String> testConnection({String? overrideKey}) async {
    final key = (overrideKey?.trim().isNotEmpty ?? false)
        ? overrideKey!.trim()
        : apiKey;
    if (key.isEmpty) return 'API key masih kosong.';
    final client = GroqClient(apiKey: key);
    try {
      final count = await client.testConnection();
      return 'Terhubung! $count model chat tersedia untuk key ini.';
    } on GroqException catch (error) {
      return error.message;
    } catch (_) {
      return 'Gagal terhubung. Periksa internet kamu.';
    } finally {
      client.close();
    }
  }

  GroqModelInfo get currentModelInfo {
    if (isAutoModel) {
      return const GroqModelInfo(
        id: kAutoModelId,
        label: kAutoModelLabel,
        note: 'Rotasi otomatis tiap generate',
      );
    }
    return _models.firstWhere(
      (m) => m.id == _settings.model,
      orElse: () => GroqModelInfo(
        id: _settings.model,
        label: _settings.model,
        note: 'Model pilihanmu',
      ),
    );
  }

  static List<GroqModelInfo> _sortModels(List<GroqModelInfo> input) {
    final known = <String, int>{
      for (var i = 0; i < GroqModelInfo.fallback.length; i++)
        GroqModelInfo.fallback[i].id: i,
    };
    final sorted = [...input];
    sorted.sort((a, b) {
      final ai = known[a.id] ?? 999;
      final bi = known[b.id] ?? 999;
      if (ai != bi) return ai.compareTo(bi);
      return a.id.compareTo(b.id);
    });
    return sorted;
  }
}
