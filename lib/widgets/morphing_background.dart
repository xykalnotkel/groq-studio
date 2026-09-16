import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Latar belakang berisi blob gradien yang bentuknya berubah perlahan.
///
/// Tidak memakai blur (mahal di HP), tapi radial gradient dengan tepi transparan
/// sehingga tetap terlihat lembut dan murah di-render.
class MorphingBackground extends StatefulWidget {
  const MorphingBackground({
    super.key,
    this.seed = 0,
    this.opacity = 0.55,
    this.colors = AppColors.brandGradient,
    this.duration = AppMotion.blob,
  });

  final int seed;
  final double opacity;
  final List<Color> colors;
  final Duration duration;

  @override
  State<MorphingBackground> createState() => _MorphingBackgroundState();
}

class _MorphingBackgroundState extends State<MorphingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BlobPainter(
              progress: _controller.value,
              seed: widget.seed,
              opacity: widget.opacity,
              colors: widget.colors,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter({
    required this.progress,
    required this.seed,
    required this.opacity,
    required this.colors,
  });

  final double progress;
  final int seed;
  final double opacity;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = progress * 2 * math.pi;

    _paintBlob(
      canvas,
      center: Offset(size.width * 0.86, size.height * 0.12),
      radius: size.width * 0.52,
      time: t,
      phase: seed * 1.7,
      colors: <Color>[
        colors.first.withValues(alpha: 0.55),
        colors.first.withValues(alpha: 0.0),
      ],
      opacity: opacity,
    );

    _paintBlob(
      canvas,
      center: Offset(size.width * 0.10, size.height * 0.34),
      radius: size.width * 0.46,
      time: t * 1.3 + 2.1,
      phase: seed * 2.3 + 1.2,
      colors: <Color>[
        colors[colors.length > 1 ? 1 : 0].withValues(alpha: 0.42),
        colors[colors.length > 1 ? 1 : 0].withValues(alpha: 0.0),
      ],
      opacity: opacity,
    );

    _paintBlob(
      canvas,
      center: Offset(size.width * 0.60, size.height * 0.78),
      radius: size.width * 0.58,
      time: t * 0.8 + 4.2,
      phase: seed * 3.1 + 2.6,
      colors: <Color>[
        colors.last.withValues(alpha: 0.30),
        colors.last.withValues(alpha: 0.0),
      ],
      opacity: opacity,
    );
  }

  void _paintBlob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double time,
    required double phase,
    required List<Color> colors,
    required double opacity,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: colors,
        stops: const <double>[0.0, 0.72],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(_blobPath(center, radius, time, phase), paint);
  }

  /// Path blob halus: titik-titik yang jari-jarinya "bernapas" mengikuti sinus,
  /// lalu dirangkai dengan kurva kuadratik lewat titik tengah.
  Path _blobPath(Offset center, double radius, double time, double phase) {
    const int points = 9;
    final pts = <Offset>[];

    for (var i = 0; i < points; i++) {
      final angle = (i / points) * 2 * math.pi;
      final wobble =
          1 +
          0.16 * math.sin(time + i * 1.7 + phase) +
          0.09 * math.cos(time * 1.7 + i * 2.3 + phase * 1.4);
      pts.add(
        Offset(
          center.dx + math.cos(angle) * radius * wobble,
          center.dy + math.sin(angle) * radius * wobble,
        ),
      );
    }

    final path = Path();
    final midFirst = Offset(
      (pts[0].dx + pts[points - 1].dx) / 2,
      (pts[0].dy + pts[points - 1].dy) / 2,
    );
    path.moveTo(midFirst.dx, midFirst.dy);

    for (var i = 0; i < points; i++) {
      final current = pts[i];
      final next = pts[(i + 1) % points];
      final mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.seed != seed ||
      oldDelegate.opacity != opacity;
}

/// Pembungkus praktis: latar belakang morph + isi layar di atasnya.
class MorphingScaffoldBody extends StatelessWidget {
  const MorphingScaffoldBody({
    super.key,
    required this.child,
    this.seed = 0,
    this.opacity = 0.42,
    this.colors = AppColors.brandGradient,
  });

  final Widget child;
  final int seed;
  final double opacity;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            child: MorphingBackground(
              seed: seed,
              opacity: opacity,
              colors: colors,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
