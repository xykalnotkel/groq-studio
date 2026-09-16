import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'constants.dart';

/// Error yang sudah dipoles supaya pesannya enak dibaca pengguna.
class GroqException implements Exception {
  GroqException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// 429 (rate limit), 5xx (server), dan error jaringan — kondisi yang
  /// layak dicoba ulang dengan model lain saat mode Auto aktif.
  bool get retryable =>
      statusCode == 429 ||
      (statusCode != null && statusCode! >= 500) ||
      message.contains('koneksi') ||
      message.contains('Koneksi') ||
      message.contains('lambat');

  @override
  String toString() => message;
}

/// Client minimal untuk Groq Cloud (OpenAI-compatible).
///
/// Mendukung:
/// * [complete] — tunggu sampai selesai, lalu kembalikan teks utuh.
/// * [stream]   — kirim potongan teks (delta) begitu datang (SSE).
/// * [speech]   — TTS Orpheus untuk hasil berbahasa Inggris.
/// * [fetchModels] — daftar model live + filter non-chat.
class GroqClient {
  GroqClient({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  static const String baseUrl = 'https://api.groq.com/openai/v1';
  static const Duration timeout = Duration(seconds: 60);

  final String apiKey;
  final http.Client _client;
  bool _closed = false;

  Map<String, String> get _headers => <String, String>{
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }

  static bool _isGptOss(String model) => model.startsWith('openai/gpt-oss');

  /// Batasi prompt & max_tokens untuk model dengan jendela konteks kecil
  /// (mis. allam-2-7b yang hanya 4096 token).
  static int _capMaxTokens(String modelId, int contextWindow, int maxTokens) {
    if (contextWindow > 0 && contextWindow <= 8192) {
      return maxTokens.clamp(256, 1536);
    }
    return maxTokens;
  }

  static String _capPrompt(String modelId, int contextWindow, String prompt) {
    if (contextWindow > 0 && contextWindow <= 8192 && prompt.length > 2200) {
      return '${prompt.substring(0, 2200)}\n[brief dipotong agar muat]';
    }
    return prompt;
  }

  Map<String, dynamic> _payload({
    required String model,
    required String system,
    required String prompt,
    required double temperature,
    required int maxTokens,
    required bool stream,
    required String reasoningEffort,
    required int contextWindow,
  }) {
    final cappedTokens = _capMaxTokens(model, contextWindow, maxTokens);

    // GPT-OSS: instruksi DITARUH DI USER MESSAGE (model ini tidak memakai
    // system prompt), tanpa reasoning stream, temperature tetap 0.6.
    if (_isGptOss(model)) {
      final merged = _capPrompt(
        model,
        contextWindow,
        'INSTRUKSI SISTEM (patuhi sepenuhnya):\n$system\n\n$prompt',
      );
      return <String, dynamic>{
        'model': model,
        'messages': <Map<String, String>>[
          <String, String>{'role': 'user', 'content': merged},
        ],
        'temperature': 0.6,
        'max_tokens': cappedTokens,
        'stream': stream,
        'include_reasoning': false,
        'reasoning_effort': reasoningEffort,
      };
    }

    final cappedPrompt = _capPrompt(model, contextWindow, prompt);
    return <String, dynamic>{
      'model': model,
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': system},
        <String, String>{'role': 'user', 'content': cappedPrompt},
      ],
      'temperature': temperature,
      'max_tokens': cappedTokens,
      'top_p': 0.95,
      'stream': stream,
    };
  }

  /// Generate tanpa streaming.
  Future<String> complete({
    required String model,
    required String system,
    required String prompt,
    required double temperature,
    required int maxTokens,
    String reasoningEffort = 'medium',
    int contextWindow = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/chat/completions');
    final response = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode(
            _payload(
              model: model,
              system: system,
              prompt: prompt,
              temperature: temperature,
              maxTokens: maxTokens,
              stream: false,
              reasoningEffort: reasoningEffort,
              contextWindow: contextWindow,
            ),
          ),
        )
        .timeout(timeout);

    _throwIfError(response.statusCode, response.body);

    final data = _decodeObject(response.body);
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map) {
          final content = message['content'];
          if (content is String) return content.trim();
        }
      }
    }
    throw GroqException(
      'Respons dari Groq kosong. Coba ganti model atau ulangi.',
    );
  }

  /// Generate dengan streaming (Server-Sent Events).
  Stream<String> stream({
    required String model,
    required String system,
    required String prompt,
    required double temperature,
    required int maxTokens,
    String reasoningEffort = 'medium',
    int contextWindow = 0,
  }) async* {
    final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'))
      ..headers.addAll(_headers..['Accept'] = 'text/event-stream')
      ..body = jsonEncode(
        _payload(
          model: model,
          system: system,
          prompt: prompt,
          temperature: temperature,
          maxTokens: maxTokens,
          stream: true,
          reasoningEffort: reasoningEffort,
          contextWindow: contextWindow,
        ),
      );

    final response = await _client.send(request).timeout(timeout);
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      _throwIfError(response.statusCode, body);
    }

    var buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final raw in lines) {
        final line = raw.trim();
        if (line.isEmpty || !line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data == '[DONE]') return;
        final delta = _extractDelta(data);
        if (delta != null && delta.isNotEmpty) yield delta;
      }
    }
  }

  /// Text-to-speech Orpheus (keluaran bahasa Inggris). Mengembalikan
  /// byte audio (MP3).
  Future<Uint8List> speech({
    required String text,
    String model = kOrpheusEnglishModel,
    double speed = 1.0,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/audio/speech'),
          headers: _headers,
          body: jsonEncode(<String, dynamic>{
            'model': model,
            // Orpheus memakai jendela kecil — potong aman.
            'input': text.length > 3500 ? text.substring(0, 3500) : text,
            'response_format': 'mp3',
            'speed': speed.clamp(0.5, 2.0),
          }),
        )
        .timeout(const Duration(seconds: 90));

    _throwIfError(
      response.statusCode,
      utf8.decode(response.bodyBytes, allowMalformed: true),
    );
    return response.bodyBytes;
  }

  /// Ambil daftar model yang tersedia untuk API key ini.
  Future<List<GroqModelInfo>> fetchModels() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/models'), headers: _headers)
        .timeout(const Duration(seconds: 30));

    _throwIfError(response.statusCode, response.body);

    final data = _decodeObject(response.body);
    final list = data['data'];
    if (list is! List) return GroqModelInfo.fallback;

    final models = <GroqModelInfo>[];
    for (final entry in list.whereType<Map<String, dynamic>>()) {
      if (entry['active'] == false) continue;
      final id = (entry['id'] ?? '').toString();
      if (id.isEmpty) continue;
      if (kNonChatModelFilters.any(id.contains)) continue;
      models.add(GroqModelInfo.fromJson(entry));
    }
    if (models.isEmpty) return GroqModelInfo.fallback;

    models.sort((a, b) => a.id.compareTo(b.id));
    return models;
  }

  /// Ping ringan untuk mengecek API key valid.
  Future<int> testConnection() async {
    final models = await fetchModels();
    return models.length;
  }

  static String? _extractDelta(String data) {
    try {
      final json = jsonDecode(data);
      if (json is! Map<String, dynamic>) return null;
      final choices = json['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) return null;
      final delta = first['delta'];
      if (delta is! Map) return null;
      final content = delta['content'];
      return content is String ? content : null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // dibiarkan: ditangani di bawah
    }
    return <String, dynamic>{};
  }

  static void _throwIfError(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) return;
    throw GroqException(_messageFor(statusCode, body), statusCode: statusCode);
  }

  static String _messageFor(int statusCode, String body) {
    String? apiMessage;
    String? apiCode;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        apiMessage = (decoded['error'] as Map)['message']?.toString();
        apiCode = (decoded['error'] as Map)['code']?.toString();
      }
    } catch (_) {
      apiMessage = null;
    }

    if (apiCode == 'model_terms_required') {
      return 'Model suara ini butuh persetujuan syarat pemakaian di '
          'console Groq. Buka console.groq.com, terima syaratnya, lalu '
          'coba lagi. Sementara itu aplikasi memakai suara perangkat.';
    }

    switch (statusCode) {
      case 400:
        return 'Permintaan ditolak Groq. Model mungkin sudah tidak tersedia. Coba model lain.';
      case 401:
      case 403:
        return 'API key tidak valid atau tidak punya akses. Cek kembali di menu Setelan.';
      case 404:
        return 'Model tidak ditemukan. Pilih model lain di Setelan.';
      case 413:
        return 'Pesan terlalu panjang untuk model ini. Coba persingkat brief-nya.';
      case 422:
        return 'Ada pengaturan yang tidak diterima model. Coba turunkan panjang atau ganti model.';
      case 429:
        return 'Kuota Groq sedang penuh. Tunggu sebentar, atau biarkan Auto pindah model.';
      case 498:
        return 'Tidak ada koneksi internet. Cek Wi-Fi atau data seluler kamu.';
      default:
        if (statusCode >= 500) {
          return 'Server Groq lagi bermasalah. Coba lagi beberapa saat.';
        }
        if (apiMessage != null && apiMessage.toLowerCase().contains('rate')) {
          return 'Kuota Groq sedang penuh. Tunggu sebentar lalu coba lagi.';
        }
        return 'Gagal menghubungi Groq. Cek koneksi dan API key, lalu ulangi.';
    }
  }
}
