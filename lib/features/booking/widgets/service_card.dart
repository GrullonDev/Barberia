import 'package:flutter/material.dart';

/// Simple service summary card for grid selection.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.title, required this.subtitle, required this.price, required this.onTap, super.key,
    this.selected = false,
  });

  final String title;
  final String subtitle; // e.g. "30 min"
  final String price; // formatted price
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;
    return AnimatedScale(
      scale: selected ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: selected ? 1 : 0.93,
        duration: const Duration(milliseconds: 220),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Card(
            elevation: selected ? 8 : 1,
            surfaceTintColor: selected ? cs.primary : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: selected ? cs.primary : cs.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(selected ? 16 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: txt.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: selected ? 17 : 16,
                    ),
                    child: Text(
                      title,
                      // Permitir más líneas cuando está seleccionada.
                      maxLines: selected ? 3 : 2,
                      overflow: selected
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: txt.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: selected ? 18 : 16,
                    ),
                    child: Text(price),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
