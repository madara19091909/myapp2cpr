import 'package:flutter/material.dart';

class AppColors {
  static const sky = Color(0xFF7FD6FF);
  static const grass = Color(0xFF6BCB3F);
  static const soil = Color(0xFFB07A3F);
  static const soilDark = Color(0xFF7A4E22);
  static const gold = Color(0xFFFFC107);
  static const green = Color(0xFF4CAF50);
  static const orange = Color(0xFFFF9800);
  static const blue = Color(0xFF29B6F6);
  static const red = Color(0xFFEF5350);
  static const purple = Color(0xFF9C6BFF);
  static const dark = Color(0xFF3E2723);
  static const cream = Color(0xFFFFF8E8);
  static const wood = Color(0xFF8D5A2B);
  static const surface = Color(0xFFFFFEFA);
  static const outline = Color(0xFFE5D4B7);
  static const muted = Color(0xFF796B59);
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
        titleTextStyle: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.dark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.outline, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.green, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.red)),
      ),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.green, selectionHandleColor: AppColors.green),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.green, linearTrackColor: Color(0xFFE5EEDC)),
    );
  }

  static const List<Shadow> outline = [Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 0)];
}
