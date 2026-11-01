import 'package:flutter/material.dart';

class AppColors {
  static const sky = Color(0xFF6EC8FF);
  static const skyDeep = Color(0xFF3BA3E8);
  static const grass = Color(0xFF5FCB45);
  static const grassDeep = Color(0xFF3FA32E);
  static const soil = Color(0xFFC48A4A);
  static const soilDark = Color(0xFF7A4A1E);
  static const gold = Color(0xFFFFC107);
  static const goldDeep = Color(0xFFE0A800);
  static const green = Color(0xFF43A047);
  static const orange = Color(0xFFFF9800);
  static const blue = Color(0xFF29B6F6);
  static const red = Color(0xFFEF5350);
  static const purple = Color(0xFF9C6BFF);
  static const dark = Color(0xFF2C1E14);
  static const cream = Color(0xFFFFF9EE);
  static const creamSoft = Color(0xFFFFF3D9);
  static const wood = Color(0xFF8B5A2B);
  static const woodDeep = Color(0xFF5C3A18);
  static const surface = Color(0xFFFFFEFA);
  static const outline = Color(0xFFE8D5B5);
  static const muted = Color(0xFF7A6A58);
  static const cardShadow = Color(0x33000000);
}

class AppTheme {
  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      secondary: AppColors.orange,
      surface: AppColors.surface,
      error: AppColors.red,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      visualDensity: VisualDensity.standard,
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.dark,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.dark,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.outline, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.outline, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.green, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.green,
        selectionHandleColor: AppColors.green,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.green,
        linearTrackColor: Color(0xFFE5EEDC),
      ),
    );
  }

  static const List<Shadow> outline = [
    Shadow(color: Colors.black38, offset: Offset(0, 1.5), blurRadius: 0),
  ];

  static const List<Shadow> softShadow = [
    Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
  ];
}
