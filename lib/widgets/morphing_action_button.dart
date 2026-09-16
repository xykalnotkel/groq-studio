import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Tombol utama yang **berubah bentuk** mengikuti keadaan:
/// idle → lebar penuh, loading → membulat jadi pil, streaming → jadi tombol stop bundar.
class MorphingActionButton extends StatefulWidget {
  const MorphingActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
    this.streaming = false,
    this.enabled = true,
    this.height = 58,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool streaming;
  final bool enabled;
  final double height;

  @override
  State<MorphingActionButton> createState() => _MorphingActionButtonState();
}

class _MorphingActionButtonState extends State<MorphingActionButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  // Bernapas halus saat sedang bekerja.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didUpdateWidget(covariant MorphingActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busy && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.busy && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool get _disabled => !widget.enabled || widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = widget.streaming;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        final width = compact ? widget.height : fullWidth;
        final radius = compact ? widget.height / 2 : 20.0;

        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final glow = widget.busy ? 0.18 + 0.22 * _pulse.value : 0.18;

            return Center(
              child: AnimatedContainer(
                duration: AppMotion.slow,
                curve: AppMotion.emphasized,
                width: width,
                height: widget.height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: compact
                      ? LinearGradient(
                          colors: <Color>[
                            theme.colorScheme.error,
                            theme.colorScheme.error.withValues(alpha: 0.75),
                          ],
                        )
                      : AppTheme.brand,
                  boxShadow: _disabled
                      ? null
                      : <BoxShadow>[
                          BoxShadow(
                            color:
                                (compact
                                        ? theme.colorScheme.error
                                        : AppColors.violet)
                                    .withValues(alpha: glow + 0.12),
                            blurRadius: compact ? 26 : 20,
                            spreadRadius: compact ? 2 : 0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(radius),
                    onTap: _disabled ? null : widget.onPressed,
                    onTapDown: _disabled
                        ? null
                        : (_) => setState(() => _pressed = true),
                    onTapUp: _disabled
                        ? null
                        : (_) => setState(() => _pressed = false),
                    onTapCancel: _disabled
                        ? null
                        : () => setState(() => _pressed = false),
                    splashFactory: InkSparkle.splashFactory,
                    child: AnimatedScale(
                      scale: _pressed ? 0.96 : 1,
                      duration: AppMotion.fast,
                      child: SizedBox(
                        width: width,
                        height: widget.height,
                        child: AnimatedSwitcher(
                          duration: AppMotion.normal,
                          switchInCurve: AppMotion.emphasized,
                          switchOutCurve: AppMotion.standard,
                          transitionBuilder: morphTransition,
                          child: _content(compact),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _content(bool compact) {
    if (compact) {
      return SizedBox(
        key: const ValueKey<String>('stop'),
        width: widget.height,
        height: widget.height,
        child: const Icon(Icons.stop_rounded, color: Colors.white, size: 26),
      );
    }

    if (widget.busy) {
      return Row(
        key: const ValueKey<String>('loading'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Sedang menulis…',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      key: const ValueKey<String>('idle'),
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(widget.icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Garis progres bergaya "morph" yang dipakai saat streaming.
class MorphingProgressLine extends StatefulWidget {
  const MorphingProgressLine({super.key, required this.color});

  final Color color;

  @override
  State<MorphingProgressLine> createState() => _MorphingProgressLineState();
}

class _MorphingProgressLineState extends State<MorphingProgressLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 4,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Bolak-balik dari kiri ke kanan.
            final t = (_controller.value * 2) % 2;
            final x = t < 1 ? t : 2 - t;
            return Align(
              alignment: Alignment(x * 2 - 1, 0),
              child: FractionallySizedBox(
                widthFactor: 0.42,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: <Color>[
                        widget.color.withValues(alpha: 0.15),
                        widget.color,
                        widget.color.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
