import 'package:flutter/material.dart';

/// Bahasa gerak aplikasi: durasi, kurva, dan transisi "morphing".
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 340);
  static const Duration slow = Duration(milliseconds: 620);
  static const Duration blob = Duration(seconds: 22);

  /// Kurva emphasized khas Material 3 — terasa "ngalir" tapi tetap tegas.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve decelerate = Cubic(0.0, 0.0, 0.2, 1.0);
  static const Curve overshoot = Curves.easeOutBack;
}

/// Transisi halaman: fade + slide kecil + sedikit scale (terasa menyatu).
class MorphPageTransitionsBuilder extends PageTransitionsBuilder {
  const MorphPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasized,
      reverseCurve: AppMotion.standard,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

/// Transisi "morph" generik untuk AnimatedSwitcher.
Widget morphTransition(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.94, end: 1).animate(
        CurvedAnimation(parent: animation, curve: AppMotion.emphasized),
      ),
      child: child,
    ),
  );
}

/// Route perpindahan halaman dengan morph (dipakai Riwayat → Detail).
class MorphPageRoute<T> extends PageRouteBuilder<T> {
  MorphPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: AppMotion.normal,
        reverseTransitionDuration: AppMotion.normal,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasized,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}
