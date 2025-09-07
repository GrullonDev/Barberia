import 'package:flutter/material.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/app/theme.dart';
import 'package:barberia/app/theme_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) => Consumer(
    builder: (final BuildContext context, final WidgetRef ref, final Widget? _) {
      final ThemePrefs prefs = ref.watch(themeControllerProvider);
      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Barbería App',
        themeMode: prefs.mode,
        theme: buildTheme(
          brightness: Brightness.light,
          seed: prefs.seed.color,
        ),
        darkTheme: buildTheme(
          brightness: Brightness.dark,
          seed: prefs.seed.color,
        ),
        routerConfig: appRouter,
      );
    },
  );
}

