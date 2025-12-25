import 'package:flutter/material.dart';
import 'package:barberia/common/design_tokens.dart';

const Color kDefaultSeed = AppColors.primary;

ThemeData buildTheme({
  required final Brightness brightness,
  final Color seed = kDefaultSeed,
}) {
  final bool dark = brightness == Brightness.dark;

  // Manual ColorScheme construction to ensure strict adherence to our Premium Palette
  // regardless of seed generation (though we keep seed param for potential dynamic user override if verified)
  final ColorScheme scheme = ColorScheme(
    brightness: brightness,
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
    // surfaceContainer: dark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer, // Newer Flutter parameter
    error: AppColors.error,
    onError: Colors.white,
    outline: dark ? AppColors.outlineDark : AppColors.outline,
    onSurfaceVariant: dark
        ? AppColors.onSurfaceVariantDark
        : AppColors.onSurfaceVariant,
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
    fontFamily:
        baseText.bodyMedium?.fontFamily, // Ensure global font application

    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppColors.backgroundDark : AppColors.background,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: baseText.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: scheme.onSurface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),

    cardTheme: CardThemeData(
      color: dark ? AppColors.surfaceContainerDark : AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: BorderSide(
          color: scheme.outline.withValues(alpha: dark ? 0.3 : 0.5),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: scheme.error),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      hintStyle: TextStyle(
        color: dark
            ? AppColors.onSurfaceVariantDark
            : AppColors.onSurfaceVariant,
        fontSize: 14,
      ),
      labelStyle: TextStyle(
        color: dark
            ? AppColors.onSurfaceVariantDark
            : AppColors.onSurfaceVariant,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            elevation: 0, // Flat design
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.l),
            ),
            textStyle: baseText.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => Colors.white.withValues(alpha: 0.1),
            ),
          ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
        textStyle: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    iconTheme: IconThemeData(color: scheme.onSurface, size: 24),

    dividerTheme: DividerThemeData(
      color: dark ? AppColors.outlineDark : AppColors.outline,
      thickness: 1,
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
