import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Latar "quiet surface — liquid glass": gradien radial lembut yang STATIS.
///
/// v3.1: semua gerak dihapus. Permukaan terasa seperti kaca cair yang
/// tenang — blob lembut dengan tepi transparan, tanpa repaint berkala.
class MorphingBackground extends StatelessWidget {
  const MorphingBackground({
    super.key,
    this.seed = 0,
    this.opacity = 0.55,
    this.colors = AppColors.brandGradient,
    this.duration,
  });

  final int seed;
  final double opacity;
  final List<Color> colors;

  /// Dipertahankan untuk kompatibilitas; latar kini statis.
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GlassPainter(seed: seed, opacity: opacity, colors: colors),
        size: Size.infinite,
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({
    required this.seed,
    required this.opacity,
    required this.colors,
  });

  final int seed;
  final double opacity;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Posisi blob deterministik per seed — tenang, tidak bergerak.
    final spots = <_Spot>[
      _Spot(
        Offset(
          size.width * (0.18 + 0.10 * ((seed % 3) / 3)),
          size.height * (0.16 + 0.08 * ((seed % 5) / 5)),
        ),
        size.width * 0.85,
        colors[0 % colors.length],
      ),
      _Spot(
        Offset(
          size.width * (0.88 - 0.06 * ((seed % 4) / 4)),
          size.height * (0.34 + 0.10 * ((seed % 7) / 7)),
        ),
        size.width * 0.75,
        colors[1 % colors.length],
      ),
      _Spot(
        Offset(
          size.width * (0.42 + 0.08 * ((seed % 6) / 6)),
          size.height * 0.88,
        ),
        size.width * 0.9,
        colors[2 % colors.length],
      ),
    ];

    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
    );
    for (final spot in spots) {
      final paint = Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                spot.color.withValues(alpha: 0.34),
                spot.color.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(center: spot.center, radius: spot.radius),
            );
      canvas.drawCircle(spot.center, spot.radius, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.seed != seed || old.opacity != opacity || old.colors != colors;
}

class _Spot {
  const _Spot(this.center, this.radius, this.color);

  final Offset center;
  final double radius;
  final Color color;
}

/// Badan halaman dengan latar kaca tenang + konten di atasnya.
class MorphingScaffoldBody extends StatelessWidget {
  const MorphingScaffoldBody({
    super.key,
    required this.child,
    this.seed = 0,
    this.opacity = 0.45,
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
