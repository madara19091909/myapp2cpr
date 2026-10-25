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
  static const cream = Color(0xFFFFF3D6);
  static const wood = Color(0xFF8D5A2B);
}

class AppTheme {
  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      secondary: AppColors.orange,
      surface: const Color(0xFFFFFCF4),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.green,
        selectionHandleColor: AppColors.green,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static const List<Shadow> outline = [
    Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 0),
  ];
}
