import 'package:flutter/material.dart';

/// Paleta tomada de la identidad corporativa (naranja, café, arena y negro).
class AppColors {
  static const Color naranja = Color(0xFFE07A1F);
  static const Color cafe = Color(0xFF6B3E1F);
  static const Color arena = Color(0xFFE9CFA3);
  static const Color negro = Color(0xFF1B1410);
  static const Color crema = Color(0xFFFFF8EE);
}

class AppTheme {
  static ThemeData claro() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.naranja,
      primary: AppColors.naranja,
      secondary: AppColors.cafe,
      surface: AppColors.crema,
      brightness: Brightness.light,
    );
    return _base(scheme).copyWith(scaffoldBackgroundColor: AppColors.crema);
  }

  static ThemeData oscuro() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.naranja,
      primary: const Color(0xFFF29A4A),
      secondary: AppColors.arena,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
