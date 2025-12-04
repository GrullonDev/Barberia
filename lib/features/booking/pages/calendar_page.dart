import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/common/design_tokens.dart';
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

  DateTime _nextSaturday(final DateTime day) {
    DateTime result = day.add(const Duration(days: 1));
    while (result.weekday != DateTime.saturday) {
      result = result.add(const Duration(days: 1));
    }
    return result;
  }

  Future<void> _openSlotsSheet(final DateTime day) async {
    final BookingDraft draft = ref.read(bookingDraftProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (final BuildContext ctx) {
        final S tr = S.of(ctx);
        final String headerRange = tr.calendar_schedule_range('08:00', '19:00');
        // Simulated loading future for skeleton (shimmer could be added later)
        final Future<void> loadFuture = Future<void>.delayed(
          const Duration(milliseconds: 600),
        );
        Widget section(String title, List<MapEntry<DateTime, SlotState>> list) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: list.map((final MapEntry<DateTime, SlotState> e) {
                  final DateTime dt = e.key;
                  final SlotState st = e.value;
                  final String label =
                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                          .replaceAll(':00', ':00');
                  final bool disabled =
                      st == SlotState.disabled ||
                      st == SlotState.occupied ||
                      st == SlotState.hold;
                  Color bg;
                  Color fg;
                  BorderSide? side;
                  switch (st) {
                    case SlotState.available:
                      bg = AppColors.primaryContainer;
                      fg = AppColors.onPrimaryContainer;
                      break;
                    case SlotState.occupied:
                      bg = isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainer;
                      fg = isDark
                          ? AppColors.onSurfaceVariantDark
                          : AppColors.onSurfaceVariant;
                      break;
                    case SlotState.hold:
                      bg = AppColors.secondaryContainer;
                      fg = AppColors.onSecondaryContainer;
                      side = BorderSide(
                        color:
                            (isDark
                                    ? AppColors.onBackground
                                    : AppColors.onPrimaryContainer)
                                .withAlpha(128),
                      );
                      break;
                    case SlotState.disabled:
                      bg = isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainer;
                      fg = isDark
                          ? AppColors.onSurfaceVariantDark
                          : AppColors.onSurfaceVariant;
                  }
                  return Opacity(
                    opacity: disabled ? 0.55 : 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: bg,
                        foregroundColor: fg,
                        side: side ?? BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.m),
                        ),
                      ),
                      onPressed: disabled
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
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
              const SizedBox(height: AppSpacing.l),
            ],
          );
        }

        Widget skeletonPill({double w = 56}) => Container(
          width: w,
          height: 36,
          decoration: BoxDecoration(
            color:
                (isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainer)
                    .withAlpha(90),
            borderRadius: BorderRadius.circular(AppRadius.m),
          ),
        );

        Widget skeletonSection(String title) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: <Widget>[
                skeletonPill(),
                skeletonPill(w: 64),
                skeletonPill(w: 52),
                skeletonPill(),
                skeletonPill(w: 60),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
          ],
        );

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.l,
              right: AppSpacing.l,
              top: AppSpacing.s,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
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
                      Text(
                        tr.calendar_slots_title(
                          '${day.day}/${day.month}',
                          headerRange,
                        ),
                        style: AppTypography.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.onSurfaceDark
                              : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      if (!loaded) ...<Widget>[
                        skeletonSection(tr.calendar_morning),
                        skeletonSection(tr.calendar_afternoon),
                      ] else ...<Widget>[
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
      if (mounted) context.pushNamed(RouteNames.details);
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
          // Cabecera horario + quick picks
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    tr.calendar_schedule_range('08:00', '19:00'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                const SizedBox(width: 6),
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
                const SizedBox(width: 6),
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
                color: cs.primary.withAlpha(38),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _SlotLegend(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr.calendar_select_hour_label,
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
          if (summary != null)
            Semantics(
              label: tr.calendar_summary_semantics(
                selectedService!.name,
                dayFmt.format(draft.dateTime!),
                timeFmt.format(draft.dateTime!),
              ),
              container: true,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.event_available, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        summary,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => context.pushNamed(RouteNames.details),
                      child: Text(tr.calendar_continue),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.outlineDark : AppColors.outline),
            ),
            boxShadow: selected ? AppShadows.soft : <BoxShadow>[],
          ),
          child: Text(
            label,
            style: AppTypography.textTheme.labelMedium?.copyWith(
              color: selected
                  ? AppColors.onPrimary
                  : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotLegend extends StatelessWidget {
  const _SlotLegend();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final S tr = S.of(context);
    return Wrap(
      spacing: AppSpacing.l,
      runSpacing: AppSpacing.s,
      children: <Widget>[
        _LegendItem(
          label: tr.calendar_legend_available,
          color: AppColors.primaryContainer,
          textColor: AppColors.onPrimaryContainer,
        ),
        _LegendItem(
          label: tr.calendar_legend_occupied,
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainer,
          textColor: isDark
              ? AppColors.onSurfaceVariantDark
              : AppColors.onSurfaceVariant,
        ),
        _LegendItem(
          label: tr.calendar_legend_hold,
          color: AppColors.secondaryContainer,
          textColor: AppColors.onSecondaryContainer,
          border: Border.all(
            color: isDark
                ? AppColors.onBackground
                : AppColors.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
    required this.textColor,
    this.border,
  });
  final String label;
  final Color color;
  final Color textColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 14,
          width: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.s),
            border: border,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Text(
          label,
          style: AppTypography.textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
