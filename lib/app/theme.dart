import 'package:flutter/material.dart';

import 'package:barberia/common/design_tokens.dart';

const Color kDefaultSeed = Color(0xFF22C55E); // acento

ThemeData buildTheme({
  required final Brightness brightness,
  final Color seed = kDefaultSeed,
}) {
  final bool dark = brightness == Brightness.dark;

  // Base ColorScheme derived from seed but overridden with our premium tokens
  final ColorScheme baseScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );

  final ColorScheme scheme = baseScheme.copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    surface: dark ? AppColors.surfaceDark : AppColors.surface,
    onSurface: dark ? AppColors.onSurfaceDark : AppColors.onSurface,
    // background: dark ? AppColors.backgroundDark : AppColors.background, // Deprecated in recent Flutter, use surface
    onSurfaceVariant: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
    outline: dark ? AppColors.outlineDark : AppColors.outline,
    error: AppColors.error,
  );

  final TextTheme baseText = AppTypography.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: dark
        ? AppColors.backgroundDark
        : AppColors.background,
    textTheme: baseText,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppColors.backgroundDark : AppColors.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: baseText.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: scheme.onSurface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: BorderSide(
          color: scheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: scheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: scheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: scheme.primary, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      hintStyle: TextStyle(
        color: dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
        textStyle: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
        textStyle: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
  );
}

// === Theme personalization support ===
enum ThemeSeedOption { emerald, indigo, rose, amber }

extension ThemeSeedColor on ThemeSeedOption {
  Color get color => switch (this) {
    ThemeSeedOption.emerald => const Color(0xFF22C55E),
    ThemeSeedOption.indigo => const Color(0xFF4F46E5),
    ThemeSeedOption.rose => const Color(0xFFE11D48),
    ThemeSeedOption.amber => const Color(0xFFF59E0B),
  };
}
