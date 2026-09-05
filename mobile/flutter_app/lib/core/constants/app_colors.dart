import 'package:flutter/material.dart';

class AppColors {
  // Stitch MCP Brand Primary & Accents ("Spatial Intelligence System")
  static const Color primary = Color(0xFF00F0FF); // Electric Spatial Cyan / Aqua
  static const Color primaryDark = Color(0xFF006970);
  static const Color primaryLight = Color(0xFF7DF4FF);
  static const Color secondary = Color(0xFFC0C1FF); // Soft Violet / Indigo Accent
  static const Color secondaryDark = Color(0xFF3131C0);
  static const Color accent = Color(0xFF00F0FF); // High-chroma Cyan
  static const Color cyanPulse = Color(0xFF00F0FF);
  static const Color tertiary = Color(0xFFFED639); // Spatial Amber / Warning

  // Functional Status Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFFED639); // Amber
  static const Color error = Color(0xFFFFB4AB); // Stitch Error
  static const Color danger = Color(0xFFEF4444);

  // Stitch MCP Exact Spatial Palette (The Void & Surface Tiers)
  static const Color bgDark = Color(0xFF0D1515); // The Void canvas (#0D1515)
  static const Color bgDarkSecondary = Color(0xFF080F10); // Surface container lowest (#080F10)
  static const Color surfaceDark = Color(0xFF151D1E); // Surface container low (#151D1E)
  static const Color surfaceDarkElevated = Color(0xFF192122); // Surface container (#192122)
  static const Color surfaceHigh = Color(0xFF232B2C); // Surface container high (#232B2C)
  static const Color cardDark = Color(0xFF151D1E);
  static const Color surfaceLightDark = Color(0xFF192122); // Input & chip background
  
  // Stitch MCP Precision Borders
  static const Color borderDark = Color(0xFF3B494B); // Outline variant (#3B494B)
  static const Color borderSubtleDark = Color(0xFF2E3637); // Surface variant / subtle line
  static const Color borderActiveDark = Color(0xFF00F0FF); // Cyan glow on active

  // Typography Tokens (Dark)
  static const Color textPrimaryDark = Color(0xFFDCE4E5); // on-surface (#DCE4E5)
  static const Color textSecondaryDark = Color(0xFFB9CACB); // on-surface-variant (#B9CACB)
  static const Color textMutedDark = Color(0xFF849495); // outline / muted (#849495)

  // Light Palette & Stitch Light Tokens
  static const Color bgLight = Color(0xFFF1F5F9); // Light slate canvas
  static const Color canvasLight = Color(0xFFF3F6F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFE6F4F1);
  static const Color surfaceMutedTeal = Color(0xFFD8F3ED);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtleLight = Color(0xFFE8EEF1);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Exact Stitch Light Theme Spatial Accents
  static const Color tealPrimary = Color(0xFF009688); // #009688 / #0D9488
  static const Color tealDark = Color(0xFF00796B);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealAccent = Color(0xFF00B4D8);
  static const Color tealButton = Color(0xFF00A3A6);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFFC0C1FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient spatialGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF006970)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF151D1E), Color(0xFF0D1515)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
