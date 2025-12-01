import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:barberia/features/booking/models/service.dart';

/// Modern service card with image placeholder, duration & price badges.
class ServiceCardModern extends StatelessWidget {
  const ServiceCardModern({
    required this.service,
    super.key,
    this.onTap,
    this.selected = false,
  });

  final Service service;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color border = selected ? cs.primary : cs.outlineVariant;
    final double iconSize = selected ? 34 : 28;
    final double nameFont = selected ? 18 : 16;
    final double priceFont = selected ? 14 : 12;
    const Duration d = Duration(milliseconds: 250);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: d,
        curve: Curves.easeOut,
        padding: EdgeInsets.all(selected ? 18 : 16),
        decoration: BoxDecoration(
          border: Border.all(color: border, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(24),
          color: cs.surfaceContainerHighest.withAlpha(
            selected ? 90 : 64,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: cs.primary.withAlpha(64),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: <Widget>[
            AnimatedContainer(
              duration: d,
              curve: Curves.easeOut,
              height: selected ? 62 : 56,
              width: selected ? 62 : 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: cs.primaryContainer,
              ),
              child: Icon(
                Icons.cut,
                color: cs.onPrimaryContainer,
                size: iconSize,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedDefaultTextStyle(
                    duration: d,
                    curve: Curves.easeOut,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: nameFont,
                    ),
                    child: Text(
                      service.name,
                      // Permitir más líneas si está seleccionada para que se lea completo.
                      maxLines: selected ? 3 : 2,
                      overflow: selected
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: d,
                    curve: Curves.easeOut,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    child: Text('${service.durationMinutes} min'),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: d,
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 14 : 10,
                vertical: selected ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(selected ? 14 : 12),
              ),
              child: AnimatedDefaultTextStyle(
                duration: d,
                curve: Curves.easeOut,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: priceFont,
                ),
                child: Text(
                  NumberFormat.currency(
                    name: 'GTQ',
                    symbol: 'Q',
                  ).format(service.price),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
