import 'package:flutter/material.dart';

/// Simple section header with optional subtitle.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    super.key,
    this.subtitle,
    this.spacing = 4,
  });

  final String title;
  final String? subtitle;
  final double spacing;

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      if (subtitle != null) ...<Widget>[
        SizedBox(height: spacing),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    ],
  );
}
