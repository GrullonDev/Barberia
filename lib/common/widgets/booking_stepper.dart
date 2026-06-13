import 'package:flutter/material.dart';

/// 3-step "Barbero / Agenda / Resumen" progress indicator shown across the
/// booking flow pages.
class BookingStepper extends StatelessWidget {
  const BookingStepper({required this.currentStep, super.key});

  /// 1-based index of the active step (1 = Barbero, 2 = Agenda, 3 = Resumen).
  final int currentStep;

  static const List<String> _labels = <String>['Barbero', 'Agenda', 'Resumen'];

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: <Widget>[
          Row(
            children: List<Widget>.generate(_labels.length * 2 - 1, (
              final int i,
            ) {
              if (i.isOdd) {
                final int stepBefore = (i ~/ 2) + 1;
                final bool done = stepBefore < currentStep;
                return Expanded(
                  child: Container(
                    height: 1,
                    color: done ? cs.primary : cs.outlineVariant,
                  ),
                );
              }
              final int step = (i ~/ 2) + 1;
              final bool active = step == currentStep;
              final bool done = step < currentStep;
              final bool highlighted = active || done;
              return Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: highlighted ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: highlighted ? cs.primary : cs.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '$step',
                  style: txt.labelLarge?.copyWith(
                    color: highlighted ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: List<Widget>.generate(_labels.length, (final int i) {
              final int step = i + 1;
              final bool active = step == currentStep;
              return Expanded(
                child: Text(
                  _labels[i].toUpperCase(),
                  textAlign: TextAlign.center,
                  style: txt.labelSmall?.copyWith(
                    color: active ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
