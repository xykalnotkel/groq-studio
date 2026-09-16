import 'package:flutter/material.dart';

import 'motion.dart';

class AppColors {
  AppColors._();

  static const Color violet = Color(0xFF7C5CFF);
  static const Color indigo = Color(0xFF5B4BFF);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color pink = Color(0xFFFF4D9D);
  static const Color mint = Color(0xFF34D399);
  static const Color amber = Color(0xFFFBBF24);

  static const List<Color> brandGradient = <Color>[indigo, violet, cyan];
  static const List<Color> warmGradient = <Color>[pink, violet];
}

class AppTheme {
  AppTheme._();

  static const double radius = 22;

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.violet,
          brightness: brightness,
          primary: AppColors.violet,
          secondary: AppColors.cyan,
          surface: dark ? const Color(0xFF0F0F1A) : const Color(0xFFF7F7FB),
        ).copyWith(
          surfaceContainerHighest: dark
              ? const Color(0xFF1A1A2B)
              : const Color(0xFFFFFFFF),
          surfaceContainer: dark
              ? const Color(0xFF15152A)
              : const Color(0xFFF1F1F7),
          outline: dark ? const Color(0xFF2C2C45) : const Color(0xFFE2E2EE),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF0A0A14)
          : const Color(0xFFF4F4FA),
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: MorphPageTransitionsBuilder(),
          TargetPlatform.iOS: MorphPageTransitionsBuilder(),
          TargetPlatform.macOS: MorphPageTransitionsBuilder(),
        },
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'PlusJakartaSans',
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? const Color(0xFF141424) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: dark ? const Color(0xFF23233A) : const Color(0xFFE9E9F2),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF15152A) : const Color(0xFFF2F2F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.violet, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: dark ? const Color(0xFF0D0D18) : Colors.white,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static LinearGradient get brand => const LinearGradient(
    colors: AppColors.brandGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get warm => const LinearGradient(
    colors: AppColors.warmGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
