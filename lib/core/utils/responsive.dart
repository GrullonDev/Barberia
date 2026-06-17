import 'package:flutter/material.dart';

abstract final class Breakpoints {
  static const double tablet = 768;
  static const double desktop = 1024;
}

/// Switches layout based on available width constraints (via [LayoutBuilder]).
/// Prefer this over reading [MediaQuery] directly in layout-sensitive widgets.
class Responsive extends StatelessWidget {
  const Responsive({
    required this.mobile,
    required this.desktop,
    this.tablet,
    super.key,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder desktop;
  final WidgetBuilder? tablet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth < Breakpoints.tablet) {
          return mobile(ctx);
        }
        if (constraints.maxWidth < Breakpoints.desktop) {
          final builder = tablet ?? desktop;
          return builder(ctx);
        }
        return desktop(ctx);
      },
    );
  }
}
