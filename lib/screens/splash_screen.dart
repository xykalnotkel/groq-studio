import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/morphing_background.dart';

/// Splash screen: logo menyala pelan + credit "Built in XyVerse".
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  late final Animation<double> _logo = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.7, curve: AppMotion.overshoot),
  );

  late final Animation<double> _text = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 1.0, curve: AppMotion.emphasized),
  );

  late final Animation<double> _glow = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0A0A14) : const Color(0xFFF4F4FA),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: IgnorePointer(child: MorphingBackground(opacity: 0.75)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _glow,
                  builder: (context, _) {
                    return Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.violet.withValues(
                              alpha: 0.15 + 0.35 * _glow.value,
                            ),
                            blurRadius: 60,
                            spreadRadius: 10 * _glow.value,
                          ),
                        ],
                      ),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.6, end: 1).animate(_logo),
                        child: FadeTransition(
                          opacity: _logo,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(34),
                            child: Image.asset(
                              'assets/app_icon_512.png',
                              width: 130,
                              height: 130,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: _text,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(_text),
                    child: Column(
                      children: <Widget>[
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) =>
                              AppTheme.brand.createShader(bounds),
                          child: Text(
                            AppInfo.name,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppInfo.tagline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 42,
            child: FadeTransition(
              opacity: _text,
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.8),
                      ),
                      color: theme.colorScheme.surface.withValues(alpha: 0.5),
                    ),
                    child: Builder(
                      builder: (context) {
                        final dark = theme.brightness == Brightness.dark;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'Built in',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Image.asset(
                              dark
                                  ? 'assets/xyverse_wordmark_white.png'
                                  : 'assets/xyverse_wordmark_black.png',
                              height: 14,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'v${AppInfo.version}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
