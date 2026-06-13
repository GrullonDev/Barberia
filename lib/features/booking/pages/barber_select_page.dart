import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/common/widgets/booking_stepper.dart';
import 'package:barberia/common/widgets/gentleman_button.dart';
import 'package:barberia/common/widgets/image_placeholder.dart';
import 'package:barberia/common/widgets/luxury_section_header.dart';
import 'package:barberia/features/booking/models/barber.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

class BarberSelectPage extends ConsumerStatefulWidget {
  const BarberSelectPage({super.key});

  @override
  ConsumerState<BarberSelectPage> createState() => _BarberSelectPageState();
}

class _BarberSelectPageState extends ConsumerState<BarberSelectPage> {
  String? _selectedBarberId;

  @override
  Widget build(final BuildContext context) {
    final TextTheme txt = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reserva tu Experiencia')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: <Widget>[
          Text(
            'Selecciona a tu barbero, agenda tu horario y confirma los '
            'detalles de tu cita.',
            style: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const BookingStepper(currentStep: 1),
          const SizedBox(height: 8),
          const LuxurySectionHeader(
            title: 'Selecciona tu Barbero',
            alignment: SectionHeaderAlign.left,
            subtitle:
                'Elige al profesional que dará vida a tu próximo estilo.',
          ),
          const SizedBox(height: 20),
          for (final Barber barber in mockBarbers) ...<Widget>[
            _BarberCard(
              barber: barber,
              selected: _selectedBarberId == barber.id,
              onTap: () => setState(() => _selectedBarberId = barber.id),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          GentlemanButton(
            label: 'Continuar',
            onPressed: _selectedBarberId == null
                ? null
                : () {
                    final Barber selected = mockBarbers.firstWhere(
                      (final Barber b) => b.id == _selectedBarberId,
                    );
                    ref
                        .read(bookingDraftProvider.notifier)
                        .setBarber(selected);
                    context.goNamed(RouteNames.calendar);
                  },
          ),
        ],
      ),
    );
  }
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({
    required this.barber,
    required this.selected,
    required this.onTap,
  });

  final Barber barber;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ImagePlaceholder(
              icon: Icons.person,
              badge: barber.level.badge,
              height: 88,
              width: 88,
              iconSize: 40,
              borderRadius: 12,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(barber.name, style: txt.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    barber.level.label,
                    style: txt.labelMedium?.copyWith(color: cs.primary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Icon(Icons.star, size: 16, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${barber.rating} (${barber.reviewCount})',
                        style: txt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    barber.specialty,
                    style: txt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
