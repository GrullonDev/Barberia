import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/common/design_tokens.dart';
import 'package:barberia/features/barber/models/barber.dart';
import 'package:barberia/features/barber/providers/barber_providers.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/l10n/app_localizations.dart';
import 'package:barberia/common/utils/responsive_helper.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

/// Estados UI del slot. Derivados del motor real:
/// - `available`: lo devolvió `SlotEngine.generateAvailable`.
/// - `occupied`: cae dentro de un booking activo del día (derivación cosmética).
/// - `disabled`: fuera de horario laboral o en el pasado.
enum SlotState { available, occupied, disabled }

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final DateTime _today = DateTime.now();
  late final DateTime _lastDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime(_today.year, _today.month, _today.day);
    _lastDay = _focusedDay.add(const Duration(days: 30));
    final BookingDraft draft = ref.read(bookingDraftProvider);
    _selectedDay = draft.date;

    // Auto-seleccionar el primer barbero disponible si el draft no trae uno.
    // Se hace en post-frame para no tocar state durante initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(bookingDraftProvider).barberId != null) {
        return;
      }
      ref.read(availableBarbersProvider.future).then((List<Barber> barbers) {
        if (!mounted || barbers.isEmpty) {
          return;
        }
        final Barber first = barbers.firstWhere(
          (Barber b) => b.isAvailable,
          orElse: () => barbers.first,
        );
        ref.read(bookingDraftProvider.notifier).setBarberId(first.id);
      });
    });
  }

  /// Genera el mapa visual del día combinando los slots libres del motor
  /// con la derivación cosmética de ocupados desde `bookingsProvider`.
  ///
  /// El paso es el tamaño del servicio seleccionado (default 30 min), para
  /// que los chips del bottom sheet cuadren con la granularidad real que
  /// el CF usará al validar.
  Map<DateTime, SlotState> _buildDaySlots({
    required DateTime day,
    required Barber barber,
    required List<DateTime> availableFromEngine,
    required int durationMinutes,
  }) {
    final List<int>? wh = barber.workingHours[day.weekday];
    if (wh == null || wh.length < 2) {
      return <DateTime, SlotState>{};
    }

    final int openH = wh[0];
    final int closeH = wh[1];
    final DateTime now = DateTime.now();
    final bool isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    // Set O(1) de slots libres según el motor (autoridad de disponibilidad).
    final Set<DateTime> availableSet = availableFromEngine.toSet();

    // Nota: `dayBookings` se consulta a través del bookingsProvider, pero
    // todo slot ocupado por un booking activo ya fue descartado por
    // `SlotEngine.generateAvailable`. Por tanto, "no en availableSet y no
    // en el pasado" ya implica "ocupado" desde el punto de vista del UI.

    final Map<DateTime, SlotState> map = <DateTime, SlotState>{};
    DateTime cursor = DateTime(day.year, day.month, day.day, openH);
    final DateTime dayClose = DateTime(day.year, day.month, day.day, closeH);
    final Duration step = Duration(minutes: durationMinutes);

    while (!cursor.add(step).isAfter(dayClose)) {
      SlotState state;
      if (isToday && cursor.isBefore(now)) {
        state = SlotState.disabled;
      } else if (availableSet.contains(cursor)) {
        state = SlotState.available;
      } else {
        state = SlotState.occupied;
      }
      map[cursor] = state;
      cursor = cursor.add(step);
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

    // Prerrequisitos: necesitamos servicio y barbero para llamar al motor.
    final Service? service = draft.service;
    final String? barberId = draft.barberId;
    if (service == null || barberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            service == null
                ? 'Selecciona un servicio primero.'
                : 'Cargando barberos disponibles...',
          ),
        ),
      );
      return;
    }

    final AvailableSlotsArgs args = AvailableSlotsArgs(
      barberId: barberId,
      day: day,
      serviceId: service.id ?? '',
      durationMinutes: service.durationMinutes,
    );

    DateTime? picked;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (final BuildContext ctx) {
        return Consumer(
          builder: (BuildContext consumerCtx, WidgetRef innerRef, _) {
            final S tr = S.of(consumerCtx);
            final ColorScheme cs = Theme.of(consumerCtx).colorScheme;
            final String headerRange = tr.calendar_schedule_range(
              '08:00',
              '19:00',
            );

            final AsyncValue<List<DateTime>> slotsAsync = innerRef.watch(
              availableSlotsProvider(args),
            );
            final AsyncValue<List<Barber>> barbersAsync = innerRef.watch(
              availableBarbersProvider,
            );

            Widget section(
              String title,
              List<MapEntry<DateTime, SlotState>> list,
            ) {
              if (list.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(consumerCtx).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: list.map((final MapEntry<DateTime, SlotState> e) {
                      final DateTime dt = e.key;
                      final SlotState st = e.value;
                      final String label =
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      final bool disabled = st != SlotState.available;
                      Color bg;
                      Color fg;
                      BoxBorder? border;
                      switch (st) {
                        case SlotState.available:
                          bg = cs.surfaceContainerHigh;
                          fg = cs.onSurface;
                          break;
                        case SlotState.occupied:
                          bg = cs.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          );
                          fg = cs.onSurfaceVariant.withValues(alpha: 0.5);
                          break;
                        case SlotState.disabled:
                          bg = Colors.transparent;
                          fg = cs.onSurfaceVariant.withValues(alpha: 0.3);
                          border = Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          );
                          break;
                      }

                      return Opacity(
                        opacity: disabled ? 0.6 : 1,
                        child: InkWell(
                          onTap: disabled
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  picked = dt;
                                  Navigator.of(consumerCtx).pop();
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

            Widget content = slotsAsync.when(
              data: (List<DateTime> available) {
                final Barber barber = barbersAsync.maybeWhen(
                  data: (List<Barber> list) => list.firstWhere(
                    (Barber b) => b.id == barberId,
                    orElse: () => Barber(
                      id: barberId,
                      name: '',
                      workingHours: Barber.defaultWorkingHours(),
                    ),
                  ),
                  orElse: () => Barber(
                    id: barberId,
                    name: '',
                    workingHours: Barber.defaultWorkingHours(),
                  ),
                );
                final Map<DateTime, SlotState> slots = _buildDaySlots(
                  day: day,
                  barber: barber,
                  availableFromEngine: available,
                  durationMinutes: service.durationMinutes,
                );
                final List<MapEntry<DateTime, SlotState>> morning = slots
                    .entries
                    .where((MapEntry<DateTime, SlotState> e) => e.key.hour < 13)
                    .toList();
                final List<MapEntry<DateTime, SlotState>> afternoon = slots
                    .entries
                    .where(
                      (MapEntry<DateTime, SlotState> e) => e.key.hour >= 13,
                    )
                    .toList();
                if (morning.isEmpty && afternoon.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Sin horarios para este día.',
                        style: Theme.of(consumerCtx).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    section(tr.calendar_morning, morning),
                    section(tr.calendar_afternoon, afternoon),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No se pudieron cargar los horarios.',
                    style: Theme.of(consumerCtx).textTheme.bodyMedium,
                  ),
                ),
              ),
            );

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: ResponsiveHelper.getResponsivePadding(context),
                  right: ResponsiveHelper.getResponsivePadding(context),
                  top: 8,
                  bottom:
                      MediaQuery.of(consumerCtx).viewInsets.bottom +
                      ResponsiveHelper.getSpacing(context, mobile: 24),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${day.day}/${day.month}',
                                style: Theme.of(consumerCtx)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                    ),
                              ),
                              Text(
                                headerRange,
                                style: Theme.of(
                                  consumerCtx,
                                ).textTheme.bodySmall,
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
                      content,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      ref.read(bookingDraftProvider.notifier).setDate(day);
      ref.read(bookingDraftProvider.notifier).setDateTime(picked!);
      if (mounted) {
        context.pushNamed(RouteNames.details);
      }
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                tr.calendar_title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      cs.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsivePadding(context),
                vertical: 12,
              ),
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadows.soft,
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
                          boxShadow: <BoxShadow>[
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SlotLegend(),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 80,
                  ), // Space for navigation bar
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
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: BorderRadius.circular(24),
              ),
              margin: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.of(context).padding.bottom +
                    100, // Float above nav bar
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
                        children: <Widget>[
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

class _SlotLegend extends StatelessWidget {
  const _SlotLegend();

  @override
  Widget build(BuildContext context) {
    final S tr = S.of(context);
    return Wrap(
      runSpacing: 8,
      spacing: 16,
      alignment: WrapAlignment.center,
      children: <Widget>[
        _LegendItem(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          label: tr.calendar_legend_available,
        ),
        _LegendItem(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          label: tr.calendar_legend_occupied,
          opacity: 0.5,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
    this.opacity = 1,
  });
  final String label;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 12,
          width: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
