import 'package:flutter/material.dart';

/// Palette validée sur le prototype visuel (artifact Kamalove) :
/// fond clair, encre pour le texte, un seul accent vif.
class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const backgroundSoft = Color(0xFFFBF8F3);
  static const ink = Color(0xFF1C1A17);
  static const muted = Color(0xFF767067);
  static const border = Color(0xFFECE6DC);
  static const accent = Color(0xFFE8502A);
  static const accentSoft = Color(0xFFFDEAE2);
  static const placeholder = Color(0xFFF1ECE2);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      surface: AppColors.background,
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.ink),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
  );
}
