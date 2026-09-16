import 'package:flutter/material.dart';

/// Bahasa gerak aplikasi v3.1: "quiet surface".
///
/// Semua pergerakan ditenangkan — hanya fade halus untuk perpindahan
/// keadaan/halaman, tanpa morph, tanpa scale memantul, tanpa blob bergerak.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve decelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Dipertahankan untuk kompatibilitas kode lama (tidak lagi dipakai
  /// untuk efek memantul).
  static const Curve overshoot = Cubic(0.2, 0.0, 0.0, 1.0);
}

/// Transisi halaman: fade tenang.
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
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AppMotion.emphasized,
        reverseCurve: AppMotion.standard,
      ),
      child: child,
    );
  }
}

/// Route perpindahan halaman dengan fade tenang.
class MorphPageRoute<T> extends PageRouteBuilder<T> {
  MorphPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: AppMotion.normal,
        reverseTransitionDuration: AppMotion.normal,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppMotion.emphasized,
            ),
            child: child,
          );
        },
      );
}
