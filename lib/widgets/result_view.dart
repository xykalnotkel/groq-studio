import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/generation_mode.dart';
import '../theme/app_theme.dart';
import 'markdown_lite.dart';
import 'morphing_action_button.dart';
import 'option_sheets.dart';

/// Menampilkan hasil generate + aksi salin/bagikan/ulangi.
class ResultView extends StatelessWidget {
  const ResultView({
    super.key,
    required this.text,
    required this.mode,
    this.model,
    this.elapsed,
    this.streaming = false,
    this.onRegenerate,
    this.onStop,
    this.padding = const EdgeInsets.all(18),
  });

  final String text;
  final GenerationMode mode;
  final String? model;
  final Duration? elapsed;
  final bool streaming;
  final VoidCallback? onRegenerate;
  final VoidCallback? onStop;
  final EdgeInsetsGeometry padding;

  int get _wordCount =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        gradient: LinearGradient(
          colors: <Color>[
            mode.color.withValues(alpha: dark ? 0.16 : 0.10),
            (dark ? const Color(0xFF141424) : Colors.white).withValues(
              alpha: 0.95,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: mode.color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: mode.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(mode.icon, size: 18, color: mode.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      mode.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _metaLine(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (streaming)
                IconButton(
                  tooltip: 'Hentikan',
                  onPressed: onStop,
                  icon: const Icon(Icons.stop_circle_rounded),
                ),
            ],
          ),
          if (streaming) ...<Widget>[
            const SizedBox(height: 12),
            MorphingProgressLine(color: mode.color),
          ],
          const Divider(height: 24),
          MarkdownLite(text, textStyle: theme.textTheme.bodyMedium),
          if (streaming)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _TypingDots(color: theme.colorScheme.primary),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _ActionChipButton(
                icon: Icons.copy_all_rounded,
                label: 'Salin',
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teks berhasil disalin ✅')),
                  );
                },
              ),
              _ActionChipButton(
                icon: Icons.share_rounded,
                label: 'Bagikan',
                onTap: () => shareText(text, subject: mode.label),
              ),
              if (onRegenerate != null)
                _ActionChipButton(
                  icon: Icons.refresh_rounded,
                  label: 'Ulangi',
                  onTap: streaming ? null : onRegenerate,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _metaLine() {
    final parts = <String>['$_wordCount kata'];
    if (model != null && model!.isNotEmpty) parts.add(model!);
    if (elapsed != null && elapsed!.inMilliseconds > 0) {
      parts.add('${(elapsed!.inMilliseconds / 1000).toStringAsFixed(1)}s');
    }
    return parts.join(' • ');
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(
          color: enabled
              ? theme.colorScheme.outline
              : theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.35),
      ),
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.color});

  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (index) {
            final t = (_controller.value * 3 - index).clamp(0.0, 1.0);
            return Opacity(
              opacity: 0.25 + 0.75 * (1 - (t * 2 - 1).abs()),
              child: Container(
                margin: const EdgeInsets.only(right: 5),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
