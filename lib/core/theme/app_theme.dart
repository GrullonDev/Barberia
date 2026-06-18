import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colour tokens ────────────────────────────────────────────────────────────

abstract final class AppColors {
  // Surface
  static const surface = Color(0xFF121414);
  static const surfaceDim = Color(0xFF121414);
  static const surfaceBright = Color(0xFF38393A);
  static const surfaceContainerLowest = Color(0xFF0C0F0F);
  static const surfaceContainerLow = Color(0xFF1A1C1C);
  static const surfaceContainer = Color(0xFF1E2020);
  static const surfaceContainerHigh = Color(0xFF282A2B);
  static const surfaceContainerHighest = Color(0xFF333535);
  static const surfaceVariant = Color(0xFF333535);
  static const surfaceTint = Color(0xFFC8C6C5);

  // On-surface
  static const onSurface = Color(0xFFE2E2E2);
  static const onSurfaceVariant = Color(0xFFC4C7C7);
  static const inverseSurface = Color(0xFFE2E2E2);
  static const inverseOnSurface = Color(0xFF2F3131);

  // Outline
  static const outline = Color(0xFF8E9192);
  static const outlineVariant = Color(0xFF444748);

  // Primary (warm silver / off-white)
  static const primary = Color(0xFFC8C6C5);
  static const onPrimary = Color(0xFF313030);
  static const primaryContainer = Color(0xFF1A1A1A);
  static const onPrimaryContainer = Color(0xFF848282);
  static const inversePrimary = Color(0xFF5F5E5E);
  static const primaryFixed = Color(0xFFE5E2E1);
  static const primaryFixedDim = Color(0xFFC8C6C5);
  static const onPrimaryFixed = Color(0xFF1C1B1B);
  static const onPrimaryFixedVariant = Color(0xFF474746);

  // Secondary (gold)
  static const secondary = Color(0xFFE9C349);
  static const onSecondary = Color(0xFF3C2F00);
  static const secondaryContainer = Color(0xFFAF8D11);
  static const onSecondaryContainer = Color(0xFF342800);
  static const secondaryFixed = Color(0xFFFFE088);
  static const secondaryFixedDim = Color(0xFFE9C349);
  static const onSecondaryFixed = Color(0xFF241A00);
  static const onSecondaryFixedVariant = Color(0xFF574500);

  // Tertiary (warm tan)
  static const tertiary = Color(0xFFDEC1AF);
  static const onTertiary = Color(0xFF3F2C20);
  static const tertiaryContainer = Color(0xFF26170C);
  static const onTertiaryContainer = Color(0xFF977E6E);
  static const tertiaryFixed = Color(0xFFFBDDCA);
  static const tertiaryFixedDim = Color(0xFFDEC1AF);
  static const onTertiaryFixed = Color(0xFF28180D);
  static const onTertiaryFixedVariant = Color(0xFF574335);

  // Error
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);

  // Background
  static const background = Color(0xFF121414);
  static const onBackground = Color(0xFFE2E2E2);
}

// ─── Spacing tokens ───────────────────────────────────────────────────────────

abstract final class AppSpacing {
  static const double base = 8;
  static const double containerMax = 1200;
  static const double gutter = 24;
  static const double marginMobile = 16;
  static const double marginDesktop = 48;

  // Derived multiples of base
  static const double xs = base / 2; // 4
  static const double sm = base; // 8
  static const double md = base * 2; // 16
  static const double lg = base * 3; // 24
  static const double xl = base * 4; // 32
  static const double xxl = base * 6; // 48
}

// ─── Border-radius tokens ─────────────────────────────────────────────────────

abstract final class AppRadius {
  static const double sm = 2; // 0.125rem
  static const double md = 6; // 0.375rem
  static const double lg = 8; // 0.5rem
  static const double xl = 12; // 0.75rem
  static const double full = 9999;

  static const borderRadiusSm = BorderRadius.all(Radius.circular(sm));
  static const borderRadiusMd = BorderRadius.all(Radius.circular(md));
  static const borderRadiusLg = BorderRadius.all(Radius.circular(lg));
  static const borderRadiusXl = BorderRadius.all(Radius.circular(xl));
  static const borderRadiusFull = BorderRadius.all(Radius.circular(full));
}

// ─── Typography ───────────────────────────────────────────────────────────────

abstract final class AppTextStyles {
  // Playfair Display — display / headline roles
  static TextStyle headlineLg({bool mobile = false}) =>
      GoogleFonts.playfairDisplay(
        fontSize: mobile ? 32 : 48,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: mobile ? null : -0.02 * (mobile ? 32 : 48),
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.onSurface,
  );

  static TextStyle get headlineSm => GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.onSurface,
  );

  // Hanken Grotesk — body / label roles
  static TextStyle get bodyLg => GoogleFonts.hankenGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.onSurface,
  );

  static TextStyle get bodyMd => GoogleFonts.hankenGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.onSurface,
  );

  static TextStyle get labelMd => GoogleFonts.hankenGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.05 * 14,
    color: AppColors.onSurface,
  );

  static TextStyle get labelSm => GoogleFonts.hankenGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.03 * 12,
    color: AppColors.onSurface,
  );
}

// ─── ColorScheme ──────────────────────────────────────────────────────────────

const _colorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  primaryContainer: AppColors.primaryContainer,
  onPrimaryContainer: AppColors.onPrimaryContainer,
  inversePrimary: AppColors.inversePrimary,
  secondary: AppColors.secondary,
  onSecondary: AppColors.onSecondary,
  secondaryContainer: AppColors.secondaryContainer,
  onSecondaryContainer: AppColors.onSecondaryContainer,
  tertiary: AppColors.tertiary,
  onTertiary: AppColors.onTertiary,
  tertiaryContainer: AppColors.tertiaryContainer,
  onTertiaryContainer: AppColors.onTertiaryContainer,
  error: AppColors.error,
  onError: AppColors.onError,
  errorContainer: AppColors.errorContainer,
  onErrorContainer: AppColors.onErrorContainer,
  surface: AppColors.surface,
  onSurface: AppColors.onSurface,
  surfaceContainerLowest: AppColors.surfaceContainerLowest,
  surfaceContainerLow: AppColors.surfaceContainerLow,
  surfaceContainer: AppColors.surfaceContainer,
  surfaceContainerHigh: AppColors.surfaceContainerHigh,
  surfaceContainerHighest: AppColors.surfaceContainerHighest,
  onSurfaceVariant: AppColors.onSurfaceVariant,
  inverseSurface: AppColors.inverseSurface,
  onInverseSurface: AppColors.inverseOnSurface,
  outline: AppColors.outline,
  outlineVariant: AppColors.outlineVariant,
  surfaceTint: AppColors.surfaceTint,
  scrim: Color(0xFF000000),
  shadow: Color(0xFF000000),
);

// ─── ThemeData ────────────────────────────────────────────────────────────────

ThemeData buildAppTheme() {
  final base = GoogleFonts.hankenGroteskTextTheme().apply(
    bodyColor: AppColors.onSurface,
    displayColor: AppColors.onSurface,
  );

  final textTheme = base.copyWith(
    displayLarge: AppTextStyles.headlineLg(),
    displayMedium: AppTextStyles.headlineMd,
    displaySmall: AppTextStyles.headlineSm,
    headlineLarge: AppTextStyles.headlineLg(),
    headlineMedium: AppTextStyles.headlineMd,
    headlineSmall: AppTextStyles.headlineSm,
    bodyLarge: AppTextStyles.bodyLg,
    bodyMedium: AppTextStyles.bodyMd,
    labelLarge: AppTextStyles.labelMd,
    labelSmall: AppTextStyles.labelSm,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceContainerLow,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTextStyles.headlineSm,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        textStyle: AppTextStyles.labelMd,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusMd,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.labelMd,
        side: const BorderSide(color: AppColors.outline),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusMd,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.labelMd,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      border: const OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusMd,
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusMd,
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusMd,
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: AppTextStyles.labelMd.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
      hintStyle: AppTextStyles.bodyMd.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceContainerLow,
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceContainerLow,
      indicatorColor: AppColors.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.secondary);
        }
        return const IconThemeData(color: AppColors.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.labelSm.copyWith(color: AppColors.secondary);
        }
        return AppTextStyles.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
        );
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceContainerHigh,
      selectedColor: AppColors.primaryContainer,
      labelStyle: AppTextStyles.labelSm,
      side: const BorderSide(color: AppColors.outlineVariant),
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusFull,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceContainerHighest,
      contentTextStyle: AppTextStyles.bodyMd.copyWith(
        color: AppColors.onSurface,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
    ),
  );
}
