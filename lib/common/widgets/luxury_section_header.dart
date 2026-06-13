import 'package:flutter/material.dart';

enum SectionHeaderAlign { center, left }

/// Serif section title with a short gold divider and optional subtitle,
/// used to introduce major sections across the customer-facing pages.
class LuxurySectionHeader extends StatelessWidget {
  const LuxurySectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.alignment = SectionHeaderAlign.center,
  });

  final String title;
  final String? subtitle;
  final SectionHeaderAlign alignment;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;
    final bool center = alignment == SectionHeaderAlign.center;

    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: txt.headlineSmall,
        ),
        const SizedBox(height: 10),
        Container(width: 48, height: 3, color: cs.primary),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: txt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
