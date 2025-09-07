import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

enum SlotState { available, occupied, hold, disabled }

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final DateTime _today = DateTime.now();
  late final DateTime _lastDay;
  // Horario de atención (Guatemala) 08:00 - 19:00
  static const int _openHour = 8;
  static const int _closeHour = 19; // hora límite (no inclusiva en generación)

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime(_today.year, _today.month, _today.day);
    _lastDay = _focusedDay.add(const Duration(days: 30));
    final BookingDraft draft = ref.read(bookingDraftProvider);
    _selectedDay = draft.date;
  }

  Map<DateTime, SlotState> _generateSlots(final DateTime day) {
    // Mock: genera slots cada 30 min en la mañana y cada 45 min después de 13:00.
    final List<DateTime> slots = <DateTime>[];
    int minute = 0;
    for (int h = _openHour; h < _closeHour; h++) {
      final bool afterNoon = h >= 13;
      final int step = afterNoon ? 45 : 30;
      minute = 0;
      while (minute < 60) {
        slots.add(DateTime(day.year, day.month, day.day, h, minute));
        minute += step;
      }
    }

    final DateTime now = DateTime.now();
    final bool isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    final Map<DateTime, SlotState> map = <DateTime, SlotState>{};
    for (final DateTime dt in slots) {
      SlotState state = SlotState.available;
      final int mod = dt.hour * 60 + dt.minute;
      if (mod % 7 == 0) {
        state = SlotState.occupied;
      } else if (mod % 11 == 0) {
        state = SlotState.hold;
      }
      // Horario fuera del rango (seguridad extra) o pasado si es hoy.
      if (dt.hour < _openHour ||
          dt.hour >= _closeHour ||
          (isToday && dt.isBefore(now))) {
        state = SlotState.disabled;
      }
      map[dt] = state;
    }
    return map;
  }

  Future<void> _openSlotsSheet(final DateTime day) async {
    final BookingDraft draft = ref.read(bookingDraftProvider);
    final Map<DateTime, SlotState> slots = _generateSlots(day);
    final List<MapEntry<DateTime, SlotState>> morning = slots.entries
        .where((final MapEntry<DateTime, SlotState> e) => e.key.hour < 13)
        .toList();
    final List<MapEntry<DateTime, SlotState>> afternoon = slots.entries
        .where((final MapEntry<DateTime, SlotState> e) => e.key.hour >= 13)
        .toList();

    DateTime? picked;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (final BuildContext ctx) {
        final ColorScheme cs = Theme.of(ctx).colorScheme;
        Widget section(String title, List<MapEntry<DateTime, SlotState>> list) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: list.map((final MapEntry<DateTime, SlotState> e) {
                  final DateTime dt = e.key;
                  final SlotState st = e.value;
                  final String label =
                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                          .replaceAll(':00', ':00');
                  final bool disabled =
                      st == SlotState.disabled || st == SlotState.occupied;
                  Color bg;
                  Color fg;
                  BorderSide? side;
                  switch (st) {
                    case SlotState.available:
                      bg = cs.primaryContainer;
                      fg = cs.onPrimaryContainer;
                      break;
                    case SlotState.occupied:
                      bg = cs.surfaceContainerHighest;
                      fg = cs.onSurfaceVariant;
                      break;
                    case SlotState.hold:
                      bg = cs.surfaceContainerHighest.withValues(alpha: 0.5);
                      fg = cs.onSurfaceVariant;
                      side = BorderSide(
                        color: cs.outline,
                        style: BorderStyle.solid,
                        width: 1,
                      );
                      break;
                    case SlotState.disabled:
                      bg = cs.surfaceContainerHighest.withValues(alpha: 0.2);
                      fg = cs.onSurfaceVariant.withValues(alpha: 0.4);
                      break;
                  }
                  return Opacity(
                    opacity: disabled ? 0.55 : 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: bg,
                        foregroundColor: fg,
                        side: side,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: disabled
                          ? null
                          : () {
                              picked = dt;
                              Navigator.of(ctx).pop();
                            },
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          );
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Slots para ${day.day}/${day.month} (Horario 08:00 - 19:00)',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  section('Mañana', morning),
                  section('Tarde', afternoon),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      ref.read(bookingDraftProvider.notifier).setDate(day);
      ref.read(bookingDraftProvider.notifier).setDateTime(picked!);
      if (mounted) context.goNamed(RouteNames.details);
    } else if (draft.date == null) {
      // Si el usuario cierra sin elegir, mantenemos la fecha seleccionada anterior.
      setState(() {});
    }
  }

  @override
  Widget build(final BuildContext context) {
    final BookingDraft draft = ref.watch(bookingDraftProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Fecha y Hora')),
      body: Column(
        children: <Widget>[
          TableCalendar<void>(
            firstDay: _today,
            lastDay: _lastDay,
            focusedDay: _focusedDay,
            currentDay: _today,
            availableGestures: AvailableGestures.horizontalSwipe,
            selectedDayPredicate: (final DateTime d) =>
                isSameDay(d, _selectedDay),
            onPageChanged: (final DateTime f) => _focusedDay = f,
            onDaySelected: (final DateTime selected, final DateTime focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _openSlotsSheet(selected);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          // Leyenda de estados de slots
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SlotLegend(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selecciona una hora',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (draft.dateTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Icon(Icons.schedule, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Hora: ${draft.dateTime!.hour.toString().padLeft(2, '0')}:${draft.dateTime!.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: draft.dateTime == null
                  ? null
                  : () => context.goNamed(RouteNames.details),
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotLegend extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Wrap(
      runSpacing: 6,
      spacing: 18,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _LegendItem(color: cs.primaryContainer, label: 'Disponible'),
        _LegendItem(color: cs.surfaceContainerHighest, label: 'Ocupado', opacity: 1),
        _LegendItem(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          label: 'Hold',
          border: Border.all(color: cs.outline, width: 1),
        ),
        _LegendItem(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
          label: 'Fuera de horario',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.opacity = 1,
    this.border,
  });

  final Color color;
  final String label;
  final double opacity;
  final BoxBorder? border;

  @override
  Widget build(final BuildContext context) {
    final TextStyle style = Theme.of(
      context,
    ).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w500);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 14,
          width: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(4),
            border: border,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}
