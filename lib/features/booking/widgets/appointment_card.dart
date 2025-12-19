import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/l10n/app_localizations.dart';

class AppointmentCard extends ConsumerWidget {
  const AppointmentCard({required this.booking, super.key, this.locale});

  final Booking booking;
  final Locale? locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.now();
    final bool past = booking.endTime.isBefore(now);
    final Locale loc = locale ?? Localizations.localeOf(context);
    final DateFormat dateFmt = DateFormat.yMMMd(loc.toLanguageTag());
    final DateFormat timeFmt = DateFormat.Hm(loc.toLanguageTag());
    final String date = dateFmt.format(booking.dateTime);
    final String range =
        '${timeFmt.format(booking.dateTime)} - ${timeFmt.format(booking.endTime)}';
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;
    final S tr = S.of(context);
    String badge;
    if (booking.status == BookingStatus.canceled) {
      badge = tr.appointment_badge_canceled;
    } else if (past) {
      badge = tr.appointment_badge_past;
    } else {
      badge = tr.appointment_badge_upcoming;
    }
    Color badgeColor;
    Color badgeText;
    if (booking.status == BookingStatus.canceled) {
      badgeColor = cs.errorContainer;
      badgeText = cs.onErrorContainer;
    } else if (past) {
      badgeColor = cs.surfaceContainerHighest;
      badgeText = cs.onSurfaceVariant;
    } else {
      badgeColor = cs.primaryContainer;
      badgeText = cs.onPrimaryContainer;
    }

    Future<void> confirmCancel() async {
      final bool? yes = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(tr.confirm_cancel_title),
          content: Text(tr.confirm_cancel_msg),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(tr.confirm_cancel_no),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(tr.confirm_cancel_yes),
            ),
          ],
        ),
      );
      if (yes == true) {
        ref.read(bookingsProvider.notifier).cancel(booking.id);
      }
    }

    Future<void> rebookFlow() async {
      // Simple placeholder: sumar 1 día misma hora
      final DateTime newStart = booking.dateTime.add(const Duration(days: 1));
      ref.read(bookingsProvider.notifier).rebook(booking.id, newStart);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr.appointment_rebook)));
    }

    Widget actionButton({
      required IconData icon,
      required String label,
      required String labelSoon,
      required String semanticsLabel,
      required VoidCallback onTap,
      bool enabled = true,
    }) => Tooltip(
      message: enabled ? label : labelSoon,
      child: Semantics(
        label: semanticsLabel,
        button: true,
        enabled: enabled,
        child: SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            onPressed: enabled ? onTap : null,
            icon: Icon(icon),
            splashRadius: 28,
          ),
        ),
      ),
    );

    return Semantics(
      label: 'Cita ${booking.serviceName} ${past ? 'pasada' : 'próxima'}',
      child: AnimatedOpacity(
        opacity: past ? .55 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  past ? Icons.history : Icons.schedule,
                  color: past ? cs.outline : cs.primary,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              booking.serviceName,
                              style: txt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              badge,
                              style: txt.labelSmall?.copyWith(
                                color: badgeText,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('$date  ·  $range', style: txt.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        'Duración: ${booking.service?.durationMinutes ?? 30} min',
                        style: txt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      if (booking.service?.extendedDescription != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            booking.service!.extendedDescription!,
                            style: txt.bodySmall?.copyWith(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (booking.customerName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Cliente: ${booking.customerName}',
                            style: txt.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: <Widget>[
                    actionButton(
                      icon: Icons.update,
                      label: tr.appointment_rebook,
                      labelSoon: tr.appointment_rebook_soon,
                      semanticsLabel: tr.appointment_rebook,
                      onTap: rebookFlow,
                      enabled: booking.status == BookingStatus.active,
                    ),
                    const SizedBox(height: 4),
                    actionButton(
                      icon: Icons.cancel_outlined,
                      label: tr.appointment_cancel,
                      labelSoon: tr.appointment_cancel_soon,
                      semanticsLabel: tr.appointment_cancel,
                      onTap: confirmCancel,
                      enabled: booking.status == BookingStatus.active && !past,
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
