import 'package:flutter/material.dart';

/// Visual style for [GentlemanButton].
enum GentlemanButtonVariant {
  /// Solid gold fill with dark text — the main call to action.
  primary,

  /// Gold outline with gold text — secondary action.
  secondary,

  /// Solid dark fill with gold text — used on light/gold backgrounds.
  dark,
}

/// Uppercase, letter-spaced button used across the customer-facing pages.
class GentlemanButton extends StatelessWidget {
  const GentlemanButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = GentlemanButtonVariant.primary,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final GentlemanButtonVariant variant;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label.toUpperCase()),
      ],
    );

    final Widget button = switch (variant) {
      GentlemanButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        child: child,
      ),
      GentlemanButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        child: child,
      ),
      GentlemanButtonVariant.dark => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: cs.onSurface,
          foregroundColor: cs.primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        onPressed: onPressed,
        child: child,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
