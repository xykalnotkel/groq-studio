import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

import 'groq_client.dart';
import 'text_utils.dart';

enum SpeechEngine { device, orpheus }

enum SpeechStatus { idle, loading, playing, paused }

/// Membacakan hasil generate dengan suara.
///
/// * Bahasa Indonesia (dan bahasa lain) → TTS bawaan perangkat
///   (`flutter_tts`), dijeda/dilanjut per kalimat.
/// * Bahasa Inggris → Groq Orpheus (`canopylabs/orpheus-v1-english`,
///   endpoint `/openai/v1/audio/speech`). Bila Orpheus belum disetujui
///   syaratnya di console Groq, aplikasi otomatis jatuh ke TTS perangkat.
class SpeechService extends ChangeNotifier {
  SpeechService(this._clientFor, [this._testing = false]);

  final GroqClient Function() _clientFor;
  final bool _testing;

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();

  SpeechStatus _status = SpeechStatus.idle;
  SpeechEngine _engine = SpeechEngine.device;
  String? _lastError;
  String? _playingModelLabel;

  List<String> _sentences = const <String>[];
  int _sentenceIndex = 0;
  bool _pausedByUser = false;
  bool _stopRequested = false;
  StreamSubscription<void>? _completeSub;

  SpeechStatus get status => _status;
  SpeechEngine get engine => _engine;
  String? get lastError => _lastError;
  String? get playingModelLabel => _playingModelLabel;
  bool get isActive => _status != SpeechStatus.idle;

  Future<void> _prepareTts() async {
    _tts.setCompletionHandler(() => _onSentenceDone());
    _tts.setErrorHandler((dynamic message) {
      _lastError = 'Suara perangkat bermasalah: $message';
      _finish();
    });
  }

  /// Mulai membacakan [text].
  Future<void> speak({
    required String text,
    required String languageCode,
    required double pitch,
    required double rate,
  }) async {
    await _cancelAll();

    final cleaned = _cleanForSpeech(text);
    if (cleaned.isEmpty) {
      _lastError = 'Tidak ada teks untuk dibacakan.';
      _setStatus(SpeechStatus.idle);
      return;
    }

    _lastError = null;
    _stopRequested = false;
    _pausedByUser = false;

    if (languageCode == 'en') {
      await _speakOrpheus(cleaned, rate: rate);
    } else {
      await _speakDevice(
        cleaned,
        languageCode: languageCode,
        pitch: pitch,
        rate: rate,
      );
    }
  }

  Future<void> _speakOrpheus(String text, {required double rate}) async {
    _engine = SpeechEngine.orpheus;
    _playingModelLabel = 'Orpheus (Groq)';
    _setStatus(SpeechStatus.loading);

    if (_testing) {
      _lastError = 'Audio tidak tersedia di mode tes.';
      _finish();
      return;
    }

    try {
      final bytes = await _clientFor().speech(text: text, speed: rate);
      if (_stopRequested) {
        _finish();
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/xystudio_orpheus.mp3');
      await file.writeAsBytes(bytes, flush: true);

      _completeSub = _player.onPlayerComplete.listen((_) => _finish());
      await _player.play(DeviceFileSource(file.path));
      _setStatus(SpeechStatus.playing);
    } on GroqException catch (error) {
      // Syarat Orpheus belum diterima di console → pakai suara perangkat.
      if (error.message.contains('syarat') || error.statusCode == 400) {
        _lastError = error.message;
        notifyListeners();
        await _speakDevice(text, languageCode: 'en-US', pitch: 1.0, rate: rate);
        return;
      }
      _lastError = error.message;
      _finish();
    } catch (error) {
      _lastError = 'Gagal memuat suara Orpheus: $error';
      _finish();
    }
  }

  Future<void> _speakDevice(
    String text, {
    required String languageCode,
    required double pitch,
    required double rate,
  }) async {
    _engine = SpeechEngine.device;
    _playingModelLabel = 'Suara perangkat';
    await _prepareTts();

    _sentences = _splitSentences(text);
    _sentenceIndex = 0;

    await _tts.setLanguage(languageCode);
    // flutter_tts: rate 0..1 (0.5 normal), pitch 0.5..2.
    await _tts.setSpeechRate((rate * 0.5).clamp(0.1, 1.0));
    await _tts.setPitch(pitch.clamp(0.5, 2.0));

    _setStatus(SpeechStatus.playing);
    await _speakCurrentSentence();
  }

  Future<void> _speakCurrentSentence() async {
    if (_stopRequested || _pausedByUser) return;
    if (_sentenceIndex >= _sentences.length) {
      _finish();
      return;
    }
    try {
      await _tts.speak(_sentences[_sentenceIndex]);
    } catch (error) {
      _lastError = 'Gagal membacakan teks: $error';
      _finish();
    }
  }

  void _onSentenceDone() {
    if (_stopRequested || _pausedByUser) return;
    _sentenceIndex += 1;
    unawaited(_speakCurrentSentence());
  }

  void pause() {
    if (_status != SpeechStatus.playing) return;
    if (_engine == SpeechEngine.orpheus) {
      unawaited(_player.pause());
    } else {
      _pausedByUser = true;
      unawaited(_tts.stop());
    }
    _setStatus(SpeechStatus.paused);
  }

  void resume() {
    if (_status != SpeechStatus.paused) return;
    if (_engine == SpeechEngine.orpheus) {
      unawaited(_player.resume());
    } else {
      _pausedByUser = false;
      // Ulangi kalimat yang sedang dibaca saat dijeda.
      unawaited(_speakCurrentSentence());
    }
    _setStatus(SpeechStatus.playing);
  }

  Future<void> stop() async {
    _stopRequested = true;
    await _cancelAll();
    _finish();
  }

  Future<void> _cancelAll() async {
    _pausedByUser = false;
    try {
      await _tts.stop();
    } catch (_) {
      // diabaikan
    }
    try {
      await _player.stop();
    } catch (_) {
      // diabaikan
    }
    await _completeSub?.cancel();
    _completeSub = null;
  }

  void _finish() {
    _setStatus(SpeechStatus.idle);
    _playingModelLabel = null;
  }

  void _setStatus(SpeechStatus next) {
    if (_status == next) return;
    _status = next;
    notifyListeners();
  }

  /// Bersihkan Markdown & emoji supaya enak didengar.
  static String _cleanForSpeech(String text) {
    var cleaned = stripEmoji(text);
    cleaned = cleaned
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .replaceAll(RegExp(r'^\s*[-•]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*>\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        .replaceAll(RegExp(r'_{2,}'), ' ')
        .replaceAll(RegExp(r'\|'), ', ');
    return cleaned.trim();
  }

  static List<String> _splitSentences(String text) {
    final parts = text
        .split(RegExp(r'(?<=[.!?…])\s+|\n+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    // Potong kalimat yang terlalu panjang untuk mesin TTS.
    final result = <String>[];
    for (final part in parts) {
      if (part.length <= 400) {
        result.add(part);
        continue;
      }
      var remaining = part;
      while (remaining.length > 400) {
        var cut = remaining.lastIndexOf(' ', 400);
        if (cut < 200) cut = 400;
        result.add(remaining.substring(0, cut));
        remaining = remaining.substring(cut).trim();
      }
      if (remaining.isNotEmpty) result.add(remaining);
    }
    return result;
  }
}
