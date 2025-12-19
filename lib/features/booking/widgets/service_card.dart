import 'package:flutter/material.dart';
import 'package:barberia/common/design_tokens.dart';

/// Simple service summary card for grid selection.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
    super.key,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return AnimatedScale(
      scale: selected ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? <Color>[
                      cs.primary.withValues(alpha: 0.15),
                      cs.primary.withValues(alpha: 0.05),
                    ]
                  : <Color>[
                      cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      cs.surfaceContainerHighest.withValues(alpha: 0.1),
                    ],
            ),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary
                            : cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cut,
                        size: 18,
                        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, size: 20, color: cs.primary),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: txt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      subtitle,
                      style: txt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      price,
                      style: txt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
