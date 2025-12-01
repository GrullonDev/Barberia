import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  // Primary Palette (Emerald - Premium & Fresh)
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFD1FAE5); // Emerald 100
  static const Color onPrimaryContainer = Color(0xFF064E3B); // Emerald 900

  // Secondary Palette (Slate/Blue Grey - Professional)
  static const Color secondary = Color(0xFF475569); // Slate 600
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFF1F5F9); // Slate 100
  static const Color onSecondaryContainer = Color(0xFF0F172A); // Slate 900

  // Neutral / Surface (Light)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceContainer = Color(0xFFF1F5F9); // Slate 100
  static const Color onSurface = Color(0xFF1E293B); // Slate 800
  static const Color onSurfaceVariant = Color(0xFF64748B); // Slate 500
  static const Color onBackground = Color(0xFF0F172A); // Slate 900
  static const Color outline = Color(0xFFE2E8F0); // Slate 200

  // Neutral / Surface (Dark)
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceContainerDark = Color(0xFF334155); // Slate 700
  static const Color onSurfaceDark = Color(0xFFF8FAFC); // Slate 50
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8); // Slate 400
  static const Color onBackgroundDark = Color(0xFFF1F5F9); // Slate 100
  static const Color outlineDark = Color(0xFF334155); // Slate 700

  // Semantic
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color success = Color(0xFF22C55E); // Green 500
}

abstract class AppTypography {
  static TextTheme get textTheme => GoogleFonts.outfitTextTheme();
}

abstract class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract class AppRadius {
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
}

abstract class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}
