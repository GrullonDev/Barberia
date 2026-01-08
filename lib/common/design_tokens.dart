import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  // Primary Palette (Gold - Premium & Luxury)
  static const Color primary = Color(0xFFD4AF37); // Metallic Gold
  static const Color onPrimary = Color(0xFF0F172A); // Dark Navy text on Gold
  static const Color primaryContainer = Color(0xFFFDE68A); // Pale Gold
  static const Color onPrimaryContainer = Color(0xFF451A03); // Dark Bronze

  // Secondary Palette (Dark Navy / Rich Black)
  static const Color secondary = Color(0xFF0F172A); // Slate 900
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFF334155); // Slate 700
  static const Color onSecondaryContainer = Color(0xFFF1F5F9); // Slate 100

  // Neutral / Surface (Light)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceContainer = Color(0xFFF1F5F9); // Slate 100
  static const Color onSurface = Color(0xFF1E293B); // Slate 800
  static const Color onSurfaceVariant = Color(0xFF64748B); // Slate 500
  static const Color onBackground = Color(0xFF0F172A); // Slate 900
  static const Color outline = Color(0xFFE2E8F0); // Slate 200

  // Neutral / Surface (Dark - Premium)
  static const Color surfaceDark = Color(0xFF1B1F23); // Rich Dark Grey
  static const Color backgroundDark = Color(0xFF050505); // Almost Black
  static const Color surfaceContainerDark = Color(0xFF27272A); // Zinc 800
  static const Color onSurfaceDark = Color(0xFFE2E8F0); // Slate 200
  static const Color onSurfaceVariantDark = Color(0xFFA1A1AA); // Zinc 400
  static const Color onBackgroundDark = Color(0xFFF8FAFC); // Slate 50
  static const Color outlineDark = Color(0xFF3F3F46); // Zinc 700

  // Semantic
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color success = Color(0xFF22C55E); // Green 500
}

abstract class AppTypography {
  // Montserrat for a modern, geometric, premium feel
  static TextTheme get textTheme {
    try {
      return GoogleFonts.montserratTextTheme();
    } catch (_) {
      // Fallback to default typography if font loading fails (e.g. offline)
      return Typography.material2021().englishLike;
    }
  }
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
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}
