import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _seed = Color(0xFF22C55E); // acento
final ColorScheme _baseScheme = ColorScheme.fromSeed(
  seedColor: _seed,
  brightness: Brightness.dark,
  surface: const Color(0xFF0E1013),
  onSurface: const Color(0xFF151A1F),
);

ThemeData buildTheme() {
  final TextTheme text = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
  return ThemeData(
    useMaterial3: true,
    colorScheme: _baseScheme,
    scaffoldBackgroundColor: _baseScheme.surface,
    textTheme: text.copyWith(
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: text.bodyMedium?.copyWith(color: const Color(0xFFE7ECEF)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _baseScheme.surface,
      elevation: 0,
      titleTextStyle: text.titleLarge?.copyWith(fontSize: 20),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF151A1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      elevation: 2,
      margin: EdgeInsets.all(12),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF1B2128),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      hintStyle: TextStyle(color: Color(0xFFA5ACB5)),
    ),
  );
}
