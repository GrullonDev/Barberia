import 'package:flutter/material.dart';

/// Helper class for responsive breakpoints
class ResponsiveHelper {
  // Breakpoints
  static const double extraSmallBreakpoint = 360; // Very small phones
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Check if current screen is extra small (very small phones)
  static bool isExtraSmall(BuildContext context) {
    return MediaQuery.of(context).size.width < extraSmallBreakpoint;
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current screen is desktop (not used in this app)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Get responsive value based on screen size
  static T responsive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
  }) {
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive padding
  static double getResponsivePadding(BuildContext context) {
    return isMobile(context)
        ? 16.0
        : 32.0; // Increased tablet padding for more noticeable difference
  }

  /// Get responsive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    return isMobile(context) ? 16.0 : 48.0; // Even more dramatic for horizontal
  }

  /// Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    return isMobile(context) ? 1.0 : 1.1;
  }

  /// Get number of columns for grid
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    return isMobile(context) ? 2 : 3;
  }

  /// Get card elevation based on screen size
  static double getCardElevation(BuildContext context) {
    return isMobile(context) ? 2.0 : 4.0;
  }

  /// Get border radius based on screen size
  static double getBorderRadius(BuildContext context) {
    return isMobile(context) ? 12.0 : 16.0;
  }

  /// Get responsive spacing
  static double getSpacing(
    BuildContext context, {
    double mobile = 8.0,
    double? tablet,
  }) {
    if (isExtraSmall(context)) {
      return mobile * 0.75; // Tighter spacing for small screens
    }
    return responsive(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
    );
  }
}
