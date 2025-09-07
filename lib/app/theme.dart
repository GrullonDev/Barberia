import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kDefaultSeed = Color(0xFF22C55E); // acento

ThemeData buildTheme({
  required final Brightness brightness,
  final Color seed = kDefaultSeed,
}) {
  final bool dark = brightness == Brightness.dark;
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    surface: dark ? const Color(0xFF0E1013) : const Color(0xFFF7F9FA),
  );

  final TextTheme baseText = GoogleFonts.interTextTheme(
    (dark ? ThemeData.dark() : ThemeData.light()).textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: baseText.copyWith(
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: baseText.bodyMedium?.copyWith(
        color: dark ? const Color(0xFFE7ECEF) : const Color(0xFF1C1F22),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      elevation: 0,
      titleTextStyle: baseText.titleLarge?.copyWith(fontSize: 20),
    ),
    cardTheme: CardThemeData(
      color: dark ? const Color(0xFF151A1F) : const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      elevation: dark ? 2 : 1,
      margin: const EdgeInsets.all(12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1B2128) : const Color(0xFFF1F3F5),
      border: const OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      hintStyle: TextStyle(
        color: dark ? const Color(0xFFA5ACB5) : const Color(0xFF6A717A),
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

