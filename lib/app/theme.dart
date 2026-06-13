import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:barberia/common/design_tokens.dart';

const Color kDefaultSeed = GentlemanColors.gold;

/// Builds the "The Gentleman" luxury theme: near-black surfaces with warm
/// gold accents and serif (Playfair Display) headings.
ThemeData buildTheme({
  required final Brightness brightness,
  final Color seed = kDefaultSeed,
}) {
  final bool dark = brightness == Brightness.dark;

  ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: GentlemanColors.gold,
    brightness: brightness,
  );
  scheme = scheme.copyWith(
    primary: GentlemanColors.gold,
    onPrimary: const Color(0xFF1A1714),
    secondary: GentlemanColors.goldBright,
    onSecondary: const Color(0xFF1A1714),
    surface: dark ? GentlemanColors.background : GentlemanColors.lightBackground,
    onSurface: dark ? GentlemanColors.cream : GentlemanColors.lightOnSurface,
    onSurfaceVariant: dark
        ? GentlemanColors.textMuted
        : GentlemanColors.lightOnSurfaceMuted,
    outline: dark ? GentlemanColors.divider : GentlemanColors.lightDivider,
    outlineVariant: dark ? GentlemanColors.divider : GentlemanColors.lightDivider,
    surfaceContainerLowest: dark
        ? GentlemanColors.background
        : GentlemanColors.lightBackground,
    surfaceContainerLow: dark
        ? GentlemanColors.surface
        : GentlemanColors.lightSurface,
    surfaceContainer: dark
        ? GentlemanColors.surface
        : GentlemanColors.lightSurface,
    surfaceContainerHigh: dark
        ? GentlemanColors.surfaceElevated
        : GentlemanColors.lightSurfaceElevated,
    surfaceContainerHighest: dark
        ? GentlemanColors.surfaceElevated
        : GentlemanColors.lightSurfaceElevated,
  );

  final TextTheme baseText = GoogleFonts.interTextTheme(
    (dark ? ThemeData.dark() : ThemeData.light()).textTheme,
  );
  final TextTheme serifText = GoogleFonts.playfairDisplayTextTheme(baseText);

  final TextTheme textTheme = baseText.copyWith(
    displayLarge: serifText.displayLarge?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    displayMedium: serifText.displayMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: serifText.displaySmall?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: serifText.headlineLarge?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: serifText.headlineMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: serifText.headlineSmall?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: serifText.titleLarge?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: serifText.titleMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: baseText.titleSmall?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: baseText.bodyLarge?.copyWith(color: scheme.onSurface),
    bodyMedium: baseText.bodyMedium?.copyWith(color: scheme.onSurface),
    bodySmall: baseText.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    labelLarge: baseText.labelLarge?.copyWith(
      color: scheme.onSurface,
      letterSpacing: 0.8,
    ),
    labelMedium: baseText.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
    labelSmall: baseText.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
  );

  final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(6),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textTheme,
    dividerColor: scheme.outlineVariant,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: serifText.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      elevation: 0,
      margin: const EdgeInsets.all(12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: buttonShape,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: buttonShape,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: scheme.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: scheme.outlineVariant),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: scheme.outlineVariant),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.surfaceContainerHighest,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.15),
      valueIndicatorColor: scheme.primary,
      valueIndicatorTextStyle: TextStyle(color: scheme.onPrimary),
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
