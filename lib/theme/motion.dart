import 'package:flutter/material.dart';

/// Bahasa gerak aplikasi: durasi, kurva, dan transisi morphing.
///
/// v3.2: animasi morphing kembali (blob, tombol, shimmer, hero).
/// Perpindahan **halaman** memakai geser (slide), bukan fade.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 340);
  static const Duration slow = Duration(milliseconds: 620);
  static const Duration blob = Duration(seconds: 22);

  /// Kurva emphasized khas Material 3 — terasa ngalir tapi tetap tegas.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve decelerate = Cubic(0.0, 0.0, 0.2, 1.0);
  static const Curve overshoot = Curves.easeOutBack;
}

/// Transisi halaman: geser dari kanan, tanpa fade.
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
    return slideTogether(animation, secondaryAnimation, child);
  }
}

/// Geser masuk dari kanan; halaman lama bergeser sedikit ke kiri.
Widget slideTogether(
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final incoming = CurvedAnimation(
    parent: animation,
    curve: AppMotion.emphasized,
    reverseCurve: AppMotion.standard,
  );
  final outgoing = CurvedAnimation(
    parent: secondaryAnimation,
    curve: AppMotion.standard,
  );
  return SlideTransition(
    position: Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.18, 0),
    ).animate(outgoing),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(incoming),
      child: child,
    ),
  );
}

/// Transisi morph untuk AnimatedSwitcher (kartu hasil, isi tombol).
Widget morphTransition(Widget child, Animation<double> animation) {
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
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
        child: child,
      ),
    ),
  );
}

/// Route perpindahan halaman dengan geser (Riwayat → Detail, dll.).
class MorphPageRoute<T> extends PageRouteBuilder<T> {
  MorphPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: AppMotion.normal,
        reverseTransitionDuration: AppMotion.normal,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return slideTogether(animation, secondaryAnimation, child);
        },
      );
}
