import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'text_utils.dart';

/// Satu sumber hasil riset web.
class WebSource {
  const WebSource({required this.title, required this.url, required this.text});

  final String title;
  final String url;
  final String text;
}

/// Mesin riset web sederhana milik aplikasi sendiri:
/// 1. cari lewat DuckDuckGo (halaman HTML lite, tanpa API key),
/// 2. buka beberapa hasil teratas,
/// 3. ambil teksnya untuk dirangkum model.
class WebResearch {
  WebResearch({http.Client? client}) : _client = client ?? http.Client();

  static const String _searchUrl = 'https://html.duckduckgo.com/html/';
  static const Map<String, String> _headers = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/128.0 Mobile Safari/537.36',
    'Accept-Language': 'id-ID,id;q=0.9,en;q=0.7',
  };

  final http.Client _client;

  void close() => _client.close();

  /// Cari [topic] dan kembalikan daftar tautan + judul.
  Future<List<WebSource>> search(String topic, {int limit = 6}) async {
    final response = await _client
        .post(
          Uri.parse(_searchUrl),
          headers: _headers,
          body: <String, String>{'q': topic},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw WebResearchException(
        'Mesin pencari tidak bisa dihubungi (kode ${response.statusCode}).',
      );
    }

    final results = <WebSource>[];
    final anchorPattern = RegExp(
      r'<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>([\s\S]*?)</a>',
    );
    for (final match in anchorPattern.allMatches(response.body)) {
      final href = match.group(1) ?? '';
      final title = htmlToText(match.group(2) ?? '', maxChars: 160);
      final target = _resolveDdgHref(href);
      if (target == null || title.isEmpty) continue;
      results.add(WebSource(title: title, url: target, text: ''));
      if (results.length >= limit) break;
    }
    if (results.isEmpty) {
      throw WebResearchException(
        'Tidak ada hasil pencarian untuk topik itu. Coba kata kunci lain.',
      );
    }
    return results;
  }

  /// Buka satu URL dan ambil teks bacanya.
  Future<String> fetchPageText(String url, {int maxChars = 3000}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isScheme('http')) {
      throw WebResearchException('Alamat tidak valid: $url');
    }
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 18));
    if (response.statusCode != 200) {
      throw WebResearchException(
        'Halaman menolak dibuka (kode ${response.statusCode}).',
      );
    }
    final text = htmlToText(response.body, maxChars: maxChars);
    if (text.trim().length < 80) {
      throw WebResearchException(
        'Halaman tidak punya teks yang cukup untuk diringkas.',
      );
    }
    return text;
  }

  /// Riset penuh: cari topik, buka sampai [pages] halaman secara paralel,
  /// kembalikan sumber yang berhasil dibaca.
  Future<List<WebSource>> research(String topic, {int pages = 5}) async {
    final links = await search(topic, limit: pages + 2);
    final futures = links.take(pages + 2).map((source) async {
      try {
        final text = await fetchPageText(source.url, maxChars: 2200);
        return WebSource(title: source.title, url: source.url, text: text);
      } catch (_) {
        return null;
      }
    });
    final settled = await Future.wait(futures);
    final readable = settled.whereType<WebSource>().take(pages).toList();
    if (readable.isEmpty) {
      throw WebResearchException(
        'Semua halaman hasil pencarian gagal dibuka. Coba lagi sebentar lagi.',
      );
    }
    return readable;
  }

  /// DuckDuckGo membungkus tautan dalam redirect `/l/?uddg=<url>`.
  static String? _resolveDdgHref(String href) {
    var candidate = href;
    if (candidate.startsWith('//')) candidate = 'https:$candidate';
    final uri = Uri.tryParse(candidate);
    if (uri == null) return null;
    if (uri.path.contains('/l/') || uri.queryParameters.containsKey('uddg')) {
      final inner = uri.queryParameters['uddg'];
      if (inner == null) return null;
      final decoded = Uri.decodeComponent(inner);
      return Uri.tryParse(decoded)?.toString();
    }
    return uri.isScheme('http') ? uri.toString() : null;
  }
}

class WebResearchException implements Exception {
  WebResearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Susun blok SUMBER WEB untuk ditempelkan ke prompt model.
String sourcesToPromptBlock(List<WebSource> sources) {
  final buffer = StringBuffer();
  for (var i = 0; i < sources.length; i++) {
    final source = sources[i];
    buffer
      ..writeln('--- SUMBER ${i + 1}: ${source.title} ---')
      ..writeln('URL: ${source.url}')
      ..writeln(stripEmoji(source.text))
      ..writeln();
  }
  return buffer.toString().trimRight();
}

/// Helper kecil agar utf8 tidak dianggap unused bila hanya dipakai parsial.
String decodeBytes(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);
