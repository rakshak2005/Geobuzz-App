import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents
  static const Color primary = Color(0xFF4F46E5); // Deep Indigo / Electric Blue
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF7C3AED); // Violet
  static const Color accent = Color(0xFF06B6D4); // Cyan Accent

  // Functional Status Colors
  static const Color success = Color(0xFF16A34A); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFDC2626); // Crimson
  static const Color danger = Color(0xFFDC2626);

  // Sophisticated Obsidian Dark Palette (Section 7)
  static const Color bgDark = Color(0xFF080B14); // Near-black navy
  static const Color surfaceDark = Color(0xFF111827); // Dark elevated surface
  static const Color cardDark = Color(0xFF111827);
  static const Color surfaceLightDark = Color(0xFF1E293B); // Elevated chip / input
  static const Color borderDark = Color(0xFF1F2937); // Subtle border
  static const Color borderSubtleDark = Color(0xFF374151);

  // Typography Tokens (Dark)
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textMutedDark = Color(0xFF6B7280);

  // Light Palette
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Major Brand Moments Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF0D121F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
