import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/l10n/app_localizations.dart';

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
    // Pre-generate slots (would be fetched from backend in real app)
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (final BuildContext ctx) {
        final ColorScheme cs = Theme.of(ctx).colorScheme;
        final S tr = S.of(ctx);
        final String headerRange = tr.calendar_schedule_range('08:00', '19:00');
        // Simulated loading future
        final Future<void> loadFuture = Future<void>.delayed(
          const Duration(milliseconds: 600),
        );
        Widget section(String title, List<MapEntry<DateTime, SlotState>> list) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
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
                  BoxBorder? border;
                  switch (st) {
                    case SlotState.available:
                      bg = cs.surfaceContainerHigh;
                      fg = cs.onSurface;
                      break;
                    case SlotState.occupied:
                      bg = cs.surfaceContainerHighest.withOpacity(0.5);
                      fg = cs.onSurfaceVariant.withOpacity(0.5);
                      break;
                    case SlotState.hold:
                      bg = cs.tertiaryContainer;
                      fg = cs.onTertiaryContainer;
                      break;
                    case SlotState.disabled:
                      bg = Colors.transparent;
                      fg = cs.onSurfaceVariant.withOpacity(0.3);
                      border = Border.all(
                        color: cs.outlineVariant.withOpacity(0.5),
                      );
                      break;
                  }

                  // Highlight selection during this session if needed,
                  // but here 'picked' is local to method.

                  return Opacity(
                    opacity: disabled ? 0.6 : 1,
                    child: InkWell(
                      onTap: disabled
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              picked = dt;
                              Navigator.of(ctx).pop();
                            },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(24),
                          border: border,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          );
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: FutureBuilder<void>(
              future: loadFuture,
              builder: (final BuildContext _, final AsyncSnapshot<void> snap) {
                final bool loaded =
                    snap.connectionState == ConnectionState.done;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${day.day}/${day.month}',
                                style: Theme.of(ctx).textTheme.headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                    ),
                              ),
                              Text(
                                headerRange,
                                style: Theme.of(ctx).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Icon(
                            Icons.calendar_month,
                            color: cs.primary.withValues(alpha: 0.5),
                            size: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (!loaded)
                        const Center(child: CircularProgressIndicator())
                      else ...<Widget>[
                        section(tr.calendar_morning, morning),
                        section(tr.calendar_afternoon, afternoon),
                      ],
                    ],
                  ),
                );
              },
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

    final Service? selectedService = draft.service;
    final DateFormat dayFmt = DateFormat('d/M');
    final DateFormat timeFmt = DateFormat('HH:mm');
    final String? summary = (selectedService != null && draft.dateTime != null)
        ? '${selectedService.name} • ${dayFmt.format(draft.dateTime!)} • ${timeFmt.format(draft.dateTime!)}'
        : null;

    final S tr = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr.calendar_title)),
      body: Column(
        children: <Widget>[
          // Quick picks
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: <Widget>[
                _QuickDateChip(
                  label: tr.calendar_quick_today,
                  selected: isSameDay(_selectedDay, _today),
                  onTap: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _today.year,
                        _today.month,
                        _today.day,
                      );
                      _selectedDay = _focusedDay;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _QuickDateChip(
                  label: tr.calendar_quick_tomorrow,
                  selected: isSameDay(
                    _selectedDay,
                    _today.add(const Duration(days: 1)),
                  ),
                  onTap: () {
                    final DateTime d = _today.add(const Duration(days: 1));
                    setState(() {
                      _focusedDay = d;
                      _selectedDay = d;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _QuickDateChip(
                  label: tr.calendar_quick_next_sat,
                  selected: isSameDay(_selectedDay, _nextSaturday(_today)),
                  onTap: () {
                    final DateTime d = _nextSaturday(_today);
                    setState(() {
                      _focusedDay = d;
                      _selectedDay = d;
                    });
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TableCalendar<void>(
                      firstDay: _today,
                      lastDay: _lastDay,
                      focusedDay: _focusedDay,
                      currentDay: _today,
                      availableGestures: AvailableGestures.horizontalSwipe,
                      selectedDayPredicate: (final DateTime d) =>
                          isSameDay(d, _selectedDay),
                      onPageChanged: (final DateTime f) => _focusedDay = f,
                      onDaySelected:
                          (final DateTime selected, final DateTime focused) {
                            setState(() {
                              _selectedDay = selected;
                              _focusedDay = focused;
                            });
                            _openSlotsSheet(selected);
                          },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        selectedTextStyle: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        defaultTextStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                        weekendTextStyle: TextStyle(color: cs.error),
                        outsideDaysVisible: false,
                        cellMargin: const EdgeInsets.all(4),
                      ),
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: Theme.of(context).textTheme.titleLarge!
                            .copyWith(fontWeight: FontWeight.bold),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: cs.primary,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SlotLegend(),
                  ),
                  const SizedBox(height: 80), // Spacer for bottom summary
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: (summary != null)
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.calendar_continue,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          Text(
                            summary,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: () => context.goNamed(RouteNames.details),
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({
    required this.label,
    required this.onTap,
    required this.selected,
  });
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary
              : cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

DateTime _nextSaturday(DateTime from) {
  int add = (DateTime.saturday - from.weekday) % 7;
  if (add == 0) add = 7; // next, not today if today is Saturday
  return DateTime(from.year, from.month, from.day).add(Duration(days: add));
}

class _SlotLegend extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final S tr = S.of(context);
    return Wrap(
      runSpacing: 8,
      spacing: 16,
      alignment: WrapAlignment.center,
      children: <Widget>[
        _LegendItem(
          color: cs.surfaceContainerHigh,
          label: tr.calendar_legend_available,
        ),
        _LegendItem(
          color: cs.surfaceContainerHighest,
          label: tr.calendar_legend_occupied,
          opacity: 0.5,
        ),
        _LegendItem(
          color: cs.tertiaryContainer,
          label: tr.calendar_legend_hold,
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
          height: 12,
          width: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            shape: BoxShape.circle,
            border: border,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: style),
      ],
    );
  }
}
