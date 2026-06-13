import 'package:flutter/material.dart';

/// Gradient + icon placeholder standing in for a photo, with an optional
/// uppercase badge pill in the top-left corner.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    this.icon = Icons.content_cut,
    this.badge,
    this.height,
    this.width,
    this.borderRadius = 16,
    this.iconSize = 48,
  });

  final IconData icon;
  final String? badge;
  final double? height;
  final double? width;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              cs.surfaceContainerHighest,
              cs.surfaceContainerLow,
            ],
          ),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Stack(
          children: <Widget>[
            Center(
              child: Icon(
                icon,
                size: iconSize,
                color: cs.primary.withValues(alpha: 0.55),
              ),
            ),
            if (badge != null)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!.toUpperCase(),
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
