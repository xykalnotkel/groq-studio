/// Util teks: pembersihan emoji, penghitungan kata/karakter, dan
/// konversi HTML mentah menjadi teks polos (untuk mode Riset Web &
/// Baca URL).
library;

final RegExp _emojiRanges = RegExp(
  <String>[
    '[\u{1F000}-\u{1FAFF}]', // pictograph, emoticon, transport, dll.
    '[\u{1F1E6}-\u{1F1FF}]', // bendera (regional indicator)
    '[\u{2600}-\u{27BF}]', // misc symbols + dingbats (★ ✅ ✨)
    '[\u{2300}-\u{23FF}]', // misc technical (⌛ ⏰)
    '[\u{2B00}-\u{2BFF}]', // bintang/panah dekoratif
    '[\u{FE00}-\u{FE0F}]', // variation selector
    '[\u{200D}\u{20E3}]', // ZWJ & combining enclosing keycap
    '[\u{E0020}-\u{E007F}]', // tag characters
    '[\u{2190}-\u{21FF}]', // panah dekoratif
    '[\u{2700}-\u{27BF}]', // dingbats
    '[\u{2900}-\u{297F}]', // supplemental arrows
    '[\u{1F0A0}-\u{1F0FF}]', // kartu
    '[©®™]',
  ].join('|'),
);

final RegExp _multiSpace = RegExp(r'[ \t]{2,}');
final RegExp _blankLines = RegExp(r'\n[ \t]*\n[ \t]*(\n[ \t]*)+');

/// Buang semua emoji & simbol dekoratif, lalu rapikan spasi yang tertinggal.
/// Dipakai dua lapis: instruksi ke model sudah melarang emoji, dan hasil
/// tetap disaring di kode supaya pengguna tidak pernah melihat emoji.
String stripEmoji(String input) {
  if (input.isEmpty) return input;
  var out = input.replaceAll(_emojiRanges, '');
  out = out.replaceAll(_multiSpace, ' ');
  // Bersihkan baris yang jadi kosong melompong (mis. baris isinya emoji saja).
  out = out.replaceAllMapped(RegExp(r'^[ \t]+$', multiLine: true), (_) => '');
  out = out.replaceAll(_blankLines, '\n\n');
  return out.trimRight();
}

int countWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}

/// Ekstrak URL http(s) pertama dari sebuah teks.
Uri? firstUrl(String text) {
  final match = RegExp(r'https?://[^\s<>"\)]+').firstMatch(text);
  if (match == null) return null;
  return Uri.tryParse(match.group(0)!.replaceAll(RegExp(r'[.,;]+$'), ''));
}

/// Ubah HTML mentah jadi teks polos yang enak dibaca model.
String htmlToText(String html, {int maxChars = 3000}) {
  var text = html;

  // Buang blok yang tidak mengandung isi bacaan.
  for (final tag in const <String>[
    'script',
    'style',
    'noscript',
    'svg',
    'iframe',
    'nav',
    'header',
    'footer',
    'form',
    'aside',
  ]) {
    text = text.replaceAll(
      RegExp('<$tag[^>]*>[\\s\\S]*?</$tag>', caseSensitive: false),
      ' ',
    );
  }
  // Buang komentar HTML.
  text = text.replaceAll(RegExp('<!--[\\s\\S]*?-->'), ' ');

  // Tag blok jadi baris baru supaya struktur paragraf terjaga.
  text = text.replaceAll(
    RegExp(
      r'</(p|div|section|article|li|ul|ol|h1|h2|h3|h4|h5|h6|tr|table|blockquote|br)>',
      caseSensitive: false,
    ),
    '\n',
  );
  text = text.replaceAll(RegExp(r'<br[^>]*>', caseSensitive: false), '\n');

  // Sisa tag dibuang semua.
  text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');

  text = _decodeEntities(text);

  // Rapikan whitespace.
  text = text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join('\n');

  if (text.length > maxChars) {
    text = '${text.substring(0, maxChars)} …';
  }
  return text;
}

String _decodeEntities(String input) {
  var out = input
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&rsaquo;', '›')
      .replaceAll('&lsaquo;', '‹')
      .replaceAll('&mdash;', '—')
      .replaceAll('&ndash;', '–')
      .replaceAll('&hellip;', '…')
      .replaceAll('&copy;', '(c)');
  // Entitas numerik umum.
  out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final code = int.tryParse(match.group(1) ?? '');
    if (code == null || code <= 0 || code > 0x10FFFF) return '';
    try {
      return String.fromCharCode(code);
    } catch (_) {
      return '';
    }
  });
  return out;
}
