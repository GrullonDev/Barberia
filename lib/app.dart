import 'package:flutter/material.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/app/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'Barbería App',
    theme: buildTheme(),
    darkTheme: buildTheme(),
    routerConfig: appRouter,
  );
}
