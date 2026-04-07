// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Dark theme surfaces
  static const darkBackground = Color(0xFF0F172A);
  static const darkCard = Color(0xFF1E293B);
  static const darkBorder = Color(0xFF334155);

  // Dark theme text
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF64748B);

  // Light theme surfaces
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightCard = Color(0xFFE2E8F0);
  static const lightBorder = Color(0xFFCBD5E1);

  // Light theme text
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF94A3B8);

  // Accents (same in both themes)
  static const accentBlue = Color(0xFF3B82F6);
  static const accentGreen = Color(0xFF10B981);
  static const accentAmber = Color(0xFFF59E0B);
  static const accentPurple = Color(0xFF8B5CF6);
  static const accentRed = Color(0xFFEF4444);
  static const accentGreenDark = Color(0xFF166534);
  static const accentGreenLight = Color(0xFF4ADE80);
}
