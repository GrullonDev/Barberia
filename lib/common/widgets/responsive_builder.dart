import 'package:flutter/material.dart';
import 'package:barberia/common/utils/responsive_helper.dart';

/// Widget builder for responsive layouts
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({required this.mobile, this.tablet, super.key});

  final Widget mobile;
  final Widget? tablet;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({
    required this.child,
    this.mobile = 16.0,
    this.tablet,
    super.key,
  });

  final Widget child;
  final double mobile;
  final double? tablet;

  @override
  Widget build(BuildContext context) {
    final double padding = ResponsiveHelper.responsive(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
    );

    return Padding(padding: EdgeInsets.all(padding), child: child);
  }
}

/// Responsive sized box for spacing
class ResponsiveSpacing extends StatelessWidget {
  const ResponsiveSpacing({this.mobile = 8.0, this.tablet, super.key});

  final double mobile;
  final double? tablet;

  @override
  Widget build(BuildContext context) {
    final double spacing = ResponsiveHelper.getSpacing(
      context,
      mobile: mobile,
      tablet: tablet,
    );

    return SizedBox(height: spacing, width: spacing);
  }
}
