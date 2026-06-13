import 'package:flutter/material.dart';

/// Palette for "The Gentleman" luxury barbershop theme: near-black surfaces
/// with warm gold accents and serif headings.
abstract final class GentlemanColors {
  static const Color background = Color(0xFF121110);
  static const Color surface = Color(0xFF1C1A18);
  static const Color surfaceElevated = Color(0xFF242220);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldBright = Color(0xFFE6C158);
  static const Color cream = Color(0xFFF5F1E8);
  static const Color textMuted = Color(0xFFA8A29B);
  static const Color divider = Color(0xFF332F2B);

  // Light variant for ThemeMode.light.
  static const Color lightBackground = Color(0xFFFAF6EE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1EAD9);
  static const Color lightOnSurface = Color(0xFF1C1A18);
  static const Color lightOnSurfaceMuted = Color(0xFF6E6862);
  static const Color lightDivider = Color(0xFFE3D9C4);
  static const Color goldDark = Color(0xFFB8902C);
}
