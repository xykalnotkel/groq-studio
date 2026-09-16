import 'package:flutter/material.dart';

/// Renderer Markdown sederhana (heading, daftar, quote, kode, tebal, miring).
///
/// Sengaja ditulis sendiri supaya aplikasi tidak perlu dependency ekstra.
class MarkdownLite extends StatelessWidget {
  const MarkdownLite(
    this.data, {
    super.key,
    this.textStyle,
    this.shrinkWrap = true,
  });

  final String data;
  final TextStyle? textStyle;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = (textStyle ?? theme.textTheme.bodyMedium)!.copyWith(
      height: 1.65,
      fontSize: 15,
    );

    try {
      final blocks = _buildBlocks(context, data, base, theme);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        children: blocks,
      );
    } catch (_) {
      // Jangan sampai satu baris markdown merusak seluruh tab Buat
      // (di release mode Flutter menampilkan layar abu tanpa pesan).
      return SelectableText(data, style: base);
    }
  }

  List<Widget> _buildBlocks(
    BuildContext context,
    String source,
    TextStyle base,
    ThemeData theme,
  ) {
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    final blocks = <Widget>[];
    final buffer = StringBuffer();
    var inCode = false;
    final codeBuffer = StringBuffer();

    void flushParagraph() {
      final text = buffer.toString().trim();
      buffer.clear();
      if (text.isEmpty) return;
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RichText(
            text: TextSpan(
              style: base,
              children: _parseInline(text, base, theme),
            ),
          ),
        ),
      );
    }

    for (final raw in lines) {
      final line = raw.trimRight();

      if (line.trim().startsWith('```')) {
        if (inCode) {
          blocks.add(_codeBlock(codeBuffer.toString(), base, theme));
          codeBuffer.clear();
          inCode = false;
        } else {
          flushParagraph();
          inCode = true;
        }
        continue;
      }
      if (inCode) {
        codeBuffer.writeln(line);
        continue;
      }

      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        flushParagraph();
        continue;
      }

      if (_isDivider(trimmed)) {
        flushParagraph();
        blocks.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
        );
        continue;
      }

      final heading = _headingLevel(trimmed);
      if (heading > 0) {
        flushParagraph();
        blocks.add(
          _heading(trimmed.substring(heading + 1).trim(), heading, base, theme),
        );
        continue;
      }

      final bullet = _bulletMatch(trimmed);
      if (bullet != null) {
        flushParagraph();
        blocks.add(_listItem(bullet, base, theme, numbered: false));
        continue;
      }

      final numbered = _numberedMatch(trimmed);
      if (numbered != null) {
        flushParagraph();
        blocks.add(_listItem(numbered, base, theme, numbered: true));
        continue;
      }

      if (trimmed.startsWith('> ')) {
        flushParagraph();
        blocks.add(_quote(trimmed.substring(2).trim(), base, theme));
        continue;
      }

      buffer.writeln(trimmed);
    }

    if (inCode && codeBuffer.isNotEmpty) {
      blocks.add(_codeBlock(codeBuffer.toString(), base, theme));
    }
    flushParagraph();

    return blocks;
  }

  static bool _isDivider(String line) {
    final cleaned = line.replaceAll(' ', '');
    return cleaned.length >= 3 &&
        cleaned
            .split('')
            .every((char) => char == '-' || char == '*' || char == '_');
  }

  static int _headingLevel(String line) {
    var count = 0;
    for (var i = 0; i < line.length && line[i] == '#'; i++) {
      count++;
    }
    if (count == 0 || count > 6) return 0;
    if (line.length <= count) return 0;
    return line[count] == ' ' ? count : 0;
  }

  static String? _bulletMatch(String line) {
    if (line.startsWith('- ') ||
        line.startsWith('* ') ||
        line.startsWith('• ')) {
      return line.substring(2).trim();
    }
    if (line == '-' || line == '*') return '';
    return null;
  }

  static String? _numberedMatch(String line) {
    final match = RegExp(r'^(\d+)[.)]\s+(.*)$').firstMatch(line);
    if (match == null) return null;
    return '${match.group(1)}. ${match.group(2)}';
  }

  Widget _heading(String text, int level, TextStyle base, ThemeData theme) {
    final sizes = <int, double>{1: 24, 2: 20, 3: 17, 4: 16, 5: 15, 6: 14};
    final size = sizes[level] ?? 15;
    return Padding(
      padding: EdgeInsets.only(top: level <= 2 ? 18 : 14, bottom: 8),
      child: RichText(
        text: TextSpan(
          style: base.copyWith(
            fontSize: size,
            fontWeight: FontWeight.w800,
            height: 1.35,
            color: level <= 2 ? theme.colorScheme.primary : null,
          ),
          children: _parseInline(text, base, theme),
        ),
      ),
    );
  }

  Widget _listItem(
    String text,
    TextStyle base,
    ThemeData theme, {
    required bool numbered,
  }) {
    final numberMatch = RegExp(r'^(\d+)\.\s*').firstMatch(text);
    final content = numbered && numberMatch != null
        ? text.substring(numberMatch.end)
        : text;
    final marker = numbered ? (numberMatch?.group(1) ?? '1') : null;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (marker != null)
            SizedBox(
              width: 26,
              child: Text(
                '$marker.',
                style: base.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 10),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: base,
                children: _parseInline(content, base, theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quote(String text, TextStyle base, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: base.copyWith(fontStyle: FontStyle.italic),
          children: _parseInline(text, base, theme),
        ),
      ),
    );
  }

  Widget _codeBlock(String code, TextStyle base, ThemeData theme) {
    final dark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0C0C16) : const Color(0xFFF1F1F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code.trim(),
          style: base.copyWith(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  static List<InlineSpan> _parseInline(
    String text,
    TextStyle base,
    ThemeData theme,
  ) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*|__)(.+?)\1|(\*|_)(.+?)\3|`([^`]+)`');
    var last = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      final bold = match.group(2);
      final italic = match.group(4);
      final code = match.group(5);

      if (bold != null) {
        spans.add(
          TextSpan(
            text: bold,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      } else if (italic != null) {
        spans.add(
          TextSpan(
            text: italic,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else if (code != null) {
        spans.add(
          TextSpan(
            text: code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: (base.fontSize ?? 15) - 1,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
            ),
          ),
        );
      }
      last = match.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text, style: base));
    return spans;
  }
}
