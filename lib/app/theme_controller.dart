import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/app/theme.dart';

class ThemePrefs {
  const ThemePrefs({
    required this.mode,
    required this.seed,
  });
  final ThemeMode mode;
  final ThemeSeedOption seed;

  ThemePrefs copyWith({ThemeMode? mode, ThemeSeedOption? seed}) => ThemePrefs(
        mode: mode ?? this.mode,
        seed: seed ?? this.seed,
      );
}

class ThemeController extends StateNotifier<ThemePrefs> {
  ThemeController() : super(const ThemePrefs(mode: ThemeMode.dark, seed: ThemeSeedOption.emerald));

  void setMode(final ThemeMode mode) => state = state.copyWith(mode: mode);
  void setSeed(final ThemeSeedOption seed) => state = state.copyWith(seed: seed);
}

final StateNotifierProvider<ThemeController, ThemePrefs> themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemePrefs>(
  (final Ref ref) => ThemeController(),
);
