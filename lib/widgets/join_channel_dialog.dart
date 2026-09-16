import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/controller.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Popup ajakan gabung ke saluran WhatsApp XyVerse — versi 3.0.
///
/// Gambar header dibuat ulang penuh dalam rasio 4:3 dengan gaya morphing:
/// gradien yang "meleleh", elemen melayang dengan motion blur, dan teks
/// tebal-lembut. Tanpa emoji.
///
/// * Tombol **X** di pojok untuk menutup.
/// * Centang **Jangan tampilkan lagi** disimpan permanen di perangkat.
/// * Tombol **Laporkan bug** membuka chat WhatsApp.
class JoinChannelDialog extends StatefulWidget {
  const JoinChannelDialog({super.key, required this.controller});

  final AppController controller;

  /// Tampilkan popup bila memang waktunya (dan belum dimatikan pengguna).
  static Future<void> maybeShow(
    BuildContext context,
    AppController controller,
  ) async {
    if (!controller.shouldShowChannelPopup) return;
    if (!context.mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: AppMotion.normal,
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.emphasized,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, _) => JoinChannelDialog(controller: controller),
    );
  }

  @override
  State<JoinChannelDialog> createState() => _JoinChannelDialogState();
}

class _JoinChannelDialogState extends State<JoinChannelDialog>
    with SingleTickerProviderStateMixin {
  bool _dontShowAgain = false;

  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Tidak bisa membuka $url')));
    }
  }

  Future<void> _close() async {
    if (_dontShowAgain) {
      await widget.controller.setHideChannelPopup(true);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final maxWidth = size.width > 460 ? 420.0 : size.width - 32;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _MorphingHeader(ticker: _motion, onClose: _close),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Gabung ${AppInfo.waChannelName}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dapatkan kabar fitur baru, template prompt, dan '
                          'tips nulis pakai AI — langsung di WhatsApp kamu. '
                          'Gratis.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.55,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.68,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _Benefit(
                          icon: Icons.bolt_rounded,
                          text: 'Update fitur duluan sebelum rilis',
                        ),
                        const _Benefit(
                          icon: Icons.auto_awesome_rounded,
                          text: 'Template prompt & ide konten gratis',
                        ),
                        const _Benefit(
                          icon: Icons.forum_rounded,
                          text: 'Tanya jawab langsung bareng pengguna lain',
                        ),
                        const SizedBox(height: 16),

                        // Tombol utama
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: <Color>[
                                  Color(0xFF25D366),
                                  Color(0xFF12A94B),
                                ],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0xFF25D366)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                splashFactory: InkSparkle.splashFactory,
                                onTap: () => _open(AppInfo.waChannelUrl),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.group_add_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 9),
                                    Text(
                                      'Gabung Sekarang',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            AppInfo.waChannelUrl,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10.5,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Centang "jangan tampilkan lagi"
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              setState(() => _dontShowAgain = !_dontShowAgain),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: <Widget>[
                                AnimatedContainer(
                                  duration: AppMotion.fast,
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(7),
                                    gradient: _dontShowAgain
                                        ? AppTheme.brand
                                        : null,
                                    border: Border.all(
                                      color: _dontShowAgain
                                          ? Colors.transparent
                                          : theme.colorScheme.outline,
                                      width: 1.6,
                                    ),
                                  ),
                                  child: _dontShowAgain
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 15,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Jangan tampilkan lagi',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Laporkan bug
                        Center(
                          child: TextButton.icon(
                            onPressed: () => _open(AppInfo.bugReportUrl),
                            icon: const Icon(
                              Icons.bug_report_rounded,
                              size: 17,
                            ),
                            label: const Text('Laporkan bug'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header 4:3 — gradien meleleh + elemen melayang + motion blur
// ─────────────────────────────────────────────────────────────────────────────
class _MorphingHeader extends StatelessWidget {
  const _MorphingHeader({required this.ticker, required this.onClose});

  final AnimationController ticker;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: AnimatedBuilder(
        animation: ticker,
        builder: (context, _) {
          final t = ticker.value;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Gradien dasar yang terus "meleleh".
              CustomPaint(painter: _MeltingPainter(t: t)),

              // Elemen melayang dengan motion blur.
              _FloatingOrb(
                t: t,
                phase: 0.0,
                size: 74,
                color: const Color(0xFF25D366).withValues(alpha: 0.85),
                start: const Offset(0.18, 0.30),
                drift: const Offset(0.05, -0.06),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              _FloatingOrb(
                t: t,
                phase: 0.33,
                size: 56,
                color: const Color(0xFF7C5CFF).withValues(alpha: 0.9),
                start: const Offset(0.72, 0.22),
                drift: const Offset(-0.06, 0.07),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              _FloatingOrb(
                t: t,
                phase: 0.61,
                size: 46,
                color: const Color(0xFF22D3EE).withValues(alpha: 0.85),
                start: const Offset(0.60, 0.62),
                drift: const Offset(0.07, 0.05),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              _FloatingOrb(
                t: t,
                phase: 0.82,
                size: 34,
                color: const Color(0xFFF472B6).withValues(alpha: 0.8),
                start: const Offset(0.30, 0.68),
                drift: const Offset(-0.04, -0.08),
                child: null,
              ),

              // Teks tebal-lembut di tengah.
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white.withValues(alpha: 0.14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Image.asset(
                            'assets/xyverse_icon_white.png',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'XyVerse',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Saluran WhatsApp',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.15,
                        shadows: <Shadow>[
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 18,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Update, template prompt, dan tips menulis — '
                      'langsung ke WhatsApp kamu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              // Credit resmi dengan logo XyVerse.
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          'Built in',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Image.asset(
                          'assets/xyverse_wordmark_white.png',
                          height: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tombol X.
              Positioned(
                top: 10,
                right: 10,
                child: _CircleButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Tutup',
                  onTap: onClose,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Gradien "meleleh": beberapa blob radial yang bergeser pelan ke bawah
/// sambil berganti warna, di atas dasar gelap.
class _MeltingPainter extends CustomPainter {
  _MeltingPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF12122A), Color(0xFF1B1035)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    final blobs = <_Blob>[
      _Blob(
        center: Offset(
          size.width * (0.22 + 0.10 * math.sin(t * math.pi * 2)),
          size.height * (0.28 + 0.35 * t),
        ),
        radius: size.width * 0.55,
        color: const Color(0xFF7C5CFF).withValues(alpha: 0.75),
      ),
      _Blob(
        center: Offset(
          size.width * (0.85 + 0.06 * math.cos(t * math.pi * 2)),
          size.height * (0.10 + 0.30 * ((t + 0.4) % 1.0)),
        ),
        radius: size.width * 0.5,
        color: const Color(0xFF25D366).withValues(alpha: 0.55),
      ),
      _Blob(
        center: Offset(
          size.width * (0.5 + 0.12 * math.sin((t + 0.6) * math.pi * 2)),
          size.height * (0.75 - 0.20 * t),
        ),
        radius: size.width * 0.6,
        color: const Color(0xFFF472B6).withValues(alpha: 0.4),
      ),
    ];

    canvas.saveLayer(Offset.zero & size, Paint());
    for (final blob in blobs) {
      // "Lelehan": blob diregangkan vertikal + jejak ke bawah.
      canvas.save();
      canvas.translate(blob.center.dx, blob.center.dy);
      canvas.scale(1.0, 1.45);
      final paint = Paint()
        ..blendMode = BlendMode.screen
        ..shader =
            RadialGradient(
              colors: <Color>[blob.color, blob.color.withValues(alpha: 0.0)],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: blob.radius),
            );
      canvas.drawCircle(Offset.zero, blob.radius, paint);
      canvas.restore();
    }
    canvas.restore();

    // Vignette lembut supaya teks tetap terbaca.
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.1,
        colors: <Color>[
          Colors.transparent,
          Colors.black.withValues(alpha: 0.22),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(_MeltingPainter old) => old.t != t;
}

class _Blob {
  const _Blob({
    required this.center,
    required this.radius,
    required this.color,
  });

  final Offset center;
  final double radius;
  final Color color;
}

/// Lingkaran melayang dengan jejak motion blur searah gerak.
class _FloatingOrb extends StatelessWidget {
  const _FloatingOrb({
    required this.t,
    required this.phase,
    required this.size,
    required this.color,
    required this.child,
    required this.start,
    required this.drift,
  });

  final double t;
  final double phase;
  final double size;
  final Color color;
  final Widget? child;
  final Offset start; // posisi relatif 0..1
  final Offset drift; // amplitudo gerak relatif

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cycle = ((t + phase) % 1.0) * math.pi * 2;
          final dx = drift.dx * math.sin(cycle) * constraints.maxWidth;
          final dy = drift.dy * math.cos(cycle) * constraints.maxHeight;

          final orb = Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: <BoxShadow>[
                BoxShadow(color: color, blurRadius: 26, spreadRadius: 2),
              ],
            ),
            child: child == null ? null : Center(child: child),
          );

          return Align(
            alignment: Alignment(start.dx * 2 - 1, start.dy * 2 - 1),
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: ImageFiltered(
                // Blur membesar seiring gerak → kesan motion blur.
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: 1.5 + dx.abs() * 0.08,
                  sigmaY: 1.5 + dy.abs() * 0.08,
                ),
                child: orb,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF25D366)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.42),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
