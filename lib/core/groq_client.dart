import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'constants.dart';

/// Error yang sudah dipoles supaya pesannya enak dibaca pengguna.
class GroqException implements Exception {
  GroqException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Client minimal untuk Groq Cloud (OpenAI-compatible).
///
/// Mendukung dua mode:
/// * [complete] — tunggu sampai selesai, lalu kembalikan teks utuh.
/// * [stream]   — kirim potongan teks (delta) begitu datang (SSE).
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

  Map<String, dynamic> _payload({
    required String model,
    required String system,
    required String prompt,
    required double temperature,
    required int maxTokens,
    required bool stream,
  }) => <String, dynamic>{
    'model': model,
    'messages': <Map<String, String>>[
      <String, String>{'role': 'system', 'content': system},
      <String, String>{'role': 'user', 'content': prompt},
    ],
    'temperature': temperature,
    'max_tokens': maxTokens,
    'top_p': 0.95,
    'stream': stream,
  };

  /// Generate tanpa streaming.
  Future<String> complete({
    required String model,
    required String system,
    required String prompt,
    required double temperature,
    required int maxTokens,
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
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        apiMessage = (decoded['error'] as Map)['message']?.toString();
      }
    } catch (_) {
      apiMessage = null;
    }

    final detail = apiMessage == null ? '' : '\n\nDetail: $apiMessage';

    switch (statusCode) {
      case 400:
        return 'Permintaan ditolak Groq. Model mungkin sudah tidak tersedia.$detail';
      case 401:
      case 403:
        return 'API key tidak valid atau tidak punya akses. Cek kembali di menu Setelan.$detail';
      case 404:
        return 'Endpoint/model tidak ditemukan.$detail';
      case 413:
        return 'Pesan terlalu panjang untuk model ini. Coba persingkat brief-nya.$detail';
      case 422:
        return 'Ada parameter yang tidak valid.$detail';
      case 429:
        return 'Kuota/limit Groq sedang penuh (rate limit). Tunggu sebentar lalu coba lagi.$detail';
      case 498:
        return 'Koneksi ke Groq gagal. Periksa jaringan internet kamu.$detail';
      default:
        if (statusCode >= 500) {
          return 'Server Groq sedang bermasalah (kode $statusCode). Coba lagi nanti.$detail';
        }
        return 'Gagal menghubungi Groq (kode $statusCode).$detail';
    }
  }
}
