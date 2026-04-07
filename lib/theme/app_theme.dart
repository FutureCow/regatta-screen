// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.darkBackground,
          onSurface: AppColors.darkTextPrimary,
          primary: AppColors.accentBlue,
          secondary: AppColors.accentGreen,
        ),
        cardColor: AppColors.darkCard,
        iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
        textTheme: _textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),
        useMaterial3: true,
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: const ColorScheme.light(
          surface: AppColors.lightBackground,
          onSurface: AppColors.lightTextPrimary,
          primary: AppColors.accentBlue,
          secondary: AppColors.accentGreen,
        ),
        cardColor: AppColors.lightCard,
        iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
        textTheme: _textTheme(AppColors.lightTextPrimary, AppColors.lightTextSecondary),
        useMaterial3: true,
      );

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.w800,
          color: primary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        displayMedium: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: primary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: primary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        bodyLarge: TextStyle(fontSize: 16, color: primary),
        bodyMedium: TextStyle(fontSize: 14, color: primary),
        labelSmall: TextStyle(
          fontSize: 11,
          letterSpacing: 1.5,
          color: secondary,
        ),
      );
}
