import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/controller.dart';
import '../core/speech.dart';
import '../models/generation_mode.dart';
import '../theme/app_theme.dart';
import 'markdown_lite.dart';
import 'morphing_action_button.dart';
import 'option_sheets.dart';

/// Menampilkan hasil generate + aksi salin/bagikan/ulangi/dengarkan.
///
/// Teks ditampilkan dengan animasi huruf demi huruf yang halus
/// (kecepatan bisa diatur, bisa dimatikan dari Setelan).
class ResultView extends StatefulWidget {
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
    this.controller,
    this.typewriter = true,
    this.typewriterSpeed = 5,
  });

  final String text;
  final GenerationMode mode;

  /// Label model yang menjawab (badge "dijawab oleh …").
  final String? model;
  final Duration? elapsed;
  final bool streaming;
  final VoidCallback? onRegenerate;
  final VoidCallback? onStop;
  final EdgeInsetsGeometry padding;

  /// Controller aplikasi — dibutuhkan untuk tombol Dengarkan.
  final AppController? controller;
  final bool typewriter;
  final int typewriterSpeed;

  int wordCountOf(String value) =>
      value.trim().isEmpty ? 0 : value.trim().split(RegExp(r'\s+')).length;

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  int _shown = 0;
  Timer? _ticker;
  bool _ttsPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _maybeStartTicker();
  }

  @override
  void didUpdateWidget(ResultView old) {
    super.didUpdateWidget(old);
    if (old.typewriter != widget.typewriter ||
        old.typewriterSpeed != widget.typewriterSpeed) {
      _maybeStartTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _maybeStartTicker() {
    _ticker?.cancel();
    if (!widget.typewriter) {
      _shown = widget.text.length;
      return;
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final target = widget.text.length;
      if (_shown >= target) return;

      // Kecepatan dasar dari setelan (1 = pelan, 10 = ngebut).
      var step = (widget.typewriterSpeed * 30 * 0.033).ceil();
      final behind = target - _shown;
      // Kalau tertinggal jauh (streaming deras), percepat supaya tidak
      // terasa "ngos-ngosan" mengejar teks.
      if (behind > 260) step = behind;
      setState(() {
        _shown = (_shown + step).clamp(0, target);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    if (!widget.typewriter && _shown != widget.text.length) {
      _shown = widget.text.length;
    }
    final visible = widget.text.substring(_shown.clamp(0, widget.text.length));
    final typing = widget.typewriter && _shown < widget.text.length;

    return Container(
      width: double.infinity,
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        gradient: LinearGradient(
          colors: <Color>[
            widget.mode.color.withValues(alpha: dark ? 0.16 : 0.10),
            (dark ? const Color(0xFF141424) : Colors.white).withValues(
              alpha: 0.95,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: widget.mode.color.withValues(alpha: 0.35)),
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
                  color: widget.mode.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.mode.icon,
                  size: 18,
                  color: widget.mode.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.mode.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _metaLine(visible),
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
              if (widget.streaming)
                IconButton(
                  tooltip: 'Hentikan',
                  onPressed: widget.onStop,
                  icon: const Icon(Icons.stop_circle_rounded),
                ),
            ],
          ),

          // Badge model yang menjawab.
          if (widget.model != null && widget.model!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: widget.mode.color.withValues(alpha: 0.12),
                  border: Border.all(
                    color: widget.mode.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.memory_rounded,
                      size: 12,
                      color: widget.mode.color,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'dijawab oleh ${widget.model}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.mode.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (widget.streaming) ...<Widget>[
            const SizedBox(height: 12),
            MorphingProgressLine(color: widget.mode.color),
          ],
          const Divider(height: 24),
          MarkdownLite(visible, textStyle: theme.textTheme.bodyMedium),
          if (typing || widget.streaming)
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
                  await Clipboard.setData(ClipboardData(text: widget.text));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teks berhasil disalin')),
                  );
                },
              ),
              _ActionChipButton(
                icon: Icons.share_rounded,
                label: 'Bagikan',
                onTap: () => shareText(widget.text, subject: widget.mode.label),
              ),
              if (widget.onRegenerate != null)
                _ActionChipButton(
                  icon: Icons.refresh_rounded,
                  label: 'Ulangi',
                  onTap: widget.streaming ? null : widget.onRegenerate,
                ),
              if (widget.controller != null)
                _ActionChipButton(
                  icon: Icons.record_voice_over_rounded,
                  label: 'Dengarkan',
                  onTap: widget.text.trim().isEmpty || widget.streaming
                      ? null
                      : () => setState(() => _ttsPanelOpen = !_ttsPanelOpen),
                ),
            ],
          ),
          if (_ttsPanelOpen && widget.controller != null)
            _ListenPanel(controller: widget.controller!),
        ],
      ),
    );
  }

  String _metaLine(String visible) {
    final parts = <String>['${widget.wordCountOf(visible)} kata'];
    if (widget.elapsed != null && widget.elapsed!.inMilliseconds > 0) {
      parts.add(
        '${(widget.elapsed!.inMilliseconds / 1000).toStringAsFixed(1)}s',
      );
    }
    return parts.join(' • ');
  }
}

/// Panel kontrol suara: play/pause, stop, slider nada & kecepatan.
class _ListenPanel extends StatelessWidget {
  const _ListenPanel({required this.controller});

  final AppController controller;

  Future<void> _start(BuildContext context) async {
    final settings = controller.settings;
    await controller.speech.speak(
      text: controller.output,
      languageCode: settings.language.code,
      pitch: settings.ttsPitch,
      rate: settings.ttsRate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller.speech,
      builder: (context, _) {
        final speech = controller.speech;
        final settings = controller.settings;
        final orpheus =
            speech.engine == SpeechEngine.orpheus &&
            speech.status != SpeechStatus.idle;

        return Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.55,
            ),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusLabel(speech),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (speech.status == SpeechStatus.idle)
                    FilledButton.icon(
                      onPressed: () => _start(context),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Putar'),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton.filledTonal(
                          tooltip: speech.status == SpeechStatus.paused
                              ? 'Lanjutkan'
                              : 'Jeda',
                          onPressed: speech.status == SpeechStatus.loading
                              ? null
                              : () {
                                  if (speech.status == SpeechStatus.paused) {
                                    speech.resume();
                                  } else {
                                    speech.pause();
                                  }
                                },
                          icon: Icon(
                            speech.status == SpeechStatus.paused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          tooltip: 'Berhenti',
                          onPressed: () => speech.stop(),
                          icon: const Icon(Icons.stop_rounded, size: 20),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _SliderRow(
                icon: Icons.music_note_rounded,
                label: 'Nada',
                value: settings.ttsPitch,
                enabled: !orpheus,
                onChanged: (value) => controller.updateSettings(
                  controller.settings.copyWith(ttsPitch: value),
                ),
              ),
              _SliderRow(
                icon: Icons.speed_rounded,
                label: 'Kecepatan bicara',
                value: settings.ttsRate,
                enabled: true,
                onChanged: (value) => controller.updateSettings(
                  controller.settings.copyWith(ttsRate: value),
                ),
              ),
              Text(
                orpheus
                    ? 'Suara Orpheus (Groq) — slider nada tidak berlaku '
                          'untuk suara AI.'
                    : settings.language.code == 'en'
                    ? 'Keluaran bahasa Inggris dibacakan Orpheus dari Groq.'
                    : 'Bahasa Indonesia dibacakan suara perangkat '
                          '(tanpa internet).',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              if (speech.lastError != null &&
                  speech.status == SpeechStatus.idle)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    speech.lastError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(SpeechService speech) {
    switch (speech.status) {
      case SpeechStatus.idle:
        return 'Suara siap';
      case SpeechStatus.loading:
        return 'Menyiapkan suara…';
      case SpeechStatus.playing:
        return 'Sedang membaca${speech.playingModelLabel == null ? '' : ' — ${speech.playingModelLabel}'}';
      case SpeechStatus.paused:
        return 'Dijeda';
    }
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 16,
          color: enabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(
            '$label ${value.toStringAsFixed(1)}x',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              color: enabled
                  ? null
                  : theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
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
