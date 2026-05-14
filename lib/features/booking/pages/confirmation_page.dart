import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/auth/models/user.dart' as auth_user;
import 'package:barberia/common/config/location_config.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/booking/widgets/ticket_view.dart';
import 'package:barberia/l10n/app_localizations.dart';

class ConfirmationPage extends ConsumerStatefulWidget {
  const ConfirmationPage({super.key});

  @override
  ConsumerState<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends ConsumerState<ConfirmationPage> {
  Booking? _booking;
  String? _qrData;
  bool _enqueued = false;

  void _ensureBookingScheduled() {
    if (_enqueued || _booking == null) {
      return;
    }
    _enqueued = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final List<Booking> current = ref.read(bookingsProvider);
      if (!current.any((final Booking b) => b.id == _booking!.id)) {
        ref.read(bookingsProvider.notifier).add(_booking!);
        ref.read(bookingDraftProvider.notifier).reset();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_booking == null) {
      final BookingDraft draft = ref.read(bookingDraftProvider);
      if (draft.service != null &&
          draft.dateTime != null &&
          draft.name != null &&
          (draft.phone != null || draft.email != null)) {
        final auth_user.User? currentUser = ref.read(authStateProvider);
        _booking = Booking(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: currentUser?.id ?? 'guest_01',
          serviceId: draft.service?.id ?? '',
          serviceName: draft.service?.name ?? 'Servicio',
          service: draft.service,
          dateTime: draft.dateTime!,
          customerName: draft.name!,
          customerPhone: draft.phone,
          customerEmail: draft.email,
          notes: draft.notes,
        );

        final String qrContent = LocationConfig.buildBookingUrl(_booking!.id);
        _qrData = qrContent;
        _ensureBookingScheduled();
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final S tr = S.of(context);
    final Booking? booking = _booking;
    if (booking == null) {
      return Scaffold(body: Center(child: Text(tr.confirm_incomplete)));
    }
    final String? qrData = _qrData;
    if (qrData == null) {
      return Scaffold(body: Center(child: Text(tr.confirm_incomplete)));
    }
    String two(int v) => v.toString().padLeft(2, '0');
    final DateTime start = booking.dateTime;
    final DateTime end = booking.endTime;
    final String dateStr =
        '${two(start.day)}/${two(start.month)}/${start.year}';
    final String timeRange =
        '${two(start.hour)}:${two(start.minute)} - ${two(end.hour)}:${two(end.minute)}';
    final int durMin = booking.service?.durationMinutes ?? 30;

    final ColorScheme cs = Theme.of(context).colorScheme;
    final String address = LocationConfig.address;
    final Uri mapsUri = LocationConfig.googleMapsUri();
    final Uri wazeUri = LocationConfig.wazeUri();

    return Scaffold(
      appBar: AppBar(title: Text(tr.confirm_title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TicketView(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              booking.serviceName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              tr.confirm_code_suffix(
                                'APPT-${booking.id.substring(booking.id.length - 4)}',
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$dateStr  $timeRange',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onLongPress: () async {
                          await Share.share(
                            qrData,
                            subject: 'Ubicación Barbería',
                          );
                        },
                        child: Center(
                          child: Semantics(
                            label: tr.confirm_qr_semantics,
                            child: QrImageView(data: qrData, size: 180),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 16),
                            label: Text(tr.confirm_copy_link),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: qrData),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr.confirm_link_copied),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.share, size: 16),
                            label: Text(tr.confirm_share_link),
                            onPressed: () async {
                              await Share.share(
                                qrData,
                                subject: 'Ubicación Barbería',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: <Widget>[
                          _InfoChip(
                            icon: Icons.person,
                            label: booking.customerName,
                          ),
                          if (booking.customerPhone != null)
                            _InfoChip(
                              icon: Icons.phone,
                              label: booking.customerPhone!,
                            ),
                          if (booking.customerEmail != null)
                            _InfoChip(
                              icon: Icons.email,
                              label: booking.customerEmail!,
                            ),
                          _InfoChip(icon: Icons.schedule, label: '$durMin min'),
                          if (booking.notes != null &&
                              booking.notes!.isNotEmpty)
                            _InfoChip(icon: Icons.note, label: booking.notes!),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on),
                        title: Text(address),
                        subtitle: Text(tr.confirm_open_in_maps),
                        onTap: () async {
                          // Try Google Maps first, fallback to Waze if available, else browser.
                          if (await canLaunchUrl(mapsUri)) {
                            await launchUrl(
                              mapsUri,
                              mode: LaunchMode.externalApplication,
                            );
                          } else if (await canLaunchUrl(wazeUri)) {
                            await launchUrl(
                              wazeUri,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            await launchUrl(
                              mapsUri,
                              mode: LaunchMode.platformDefault,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Repopulate draft and go to calendar
                          final notifier = ref.read(
                            bookingDraftProvider.notifier,
                          );
                          notifier.setService(
                            booking.service ??
                                Service(
                                  id: booking.serviceId,
                                  name: booking.serviceName,
                                  price: 0,
                                  durationMinutes:
                                      booking.service?.durationMinutes ?? 30,
                                  category: ServiceCategory.hair,
                                  isActive: true,
                                ),
                          );
                          notifier.setCustomerInfo(
                            name: booking.customerName,
                            phone: booking.customerPhone,
                            email: booking.customerEmail,
                            notes: booking.notes,
                          );
                          context.goNamed(RouteNames.calendar);
                        },
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Reprogramar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleCancel(context, ref, booking),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.goNamed(RouteNames.home),
                        icon: const Icon(Icons.home),
                        label: Text(tr.confirm_home),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final Event event = Event(
                            title: booking.serviceName,
                            description:
                                'Cita en Barbería para ${booking.customerName}',
                            location: LocationConfig.address,
                            startDate: booking.dateTime,
                            endDate: booking.endTime,
                            allDay: false,
                            iosParams: const IOSParams(
                              reminder: Duration(minutes: 60),
                              url:
                                  'https://www.google.com/maps/search/?api=1&query=Av.+Principal+123',
                            ),
                            androidParams: const AndroidParams(
                              emailInvites: [], // Can add customer email here
                            ),
                          );
                          if (kDebugMode) {
                            print(
                              'Intentando añadir evento al calendario: ${event.title}',
                            );
                          }
                          Add2Calendar.addEvent2Cal(event);
                        },
                        icon: const Icon(Icons.event_available),
                        label: Text(tr.confirm_add_calendar),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 100,
                ), // Fixed space for bottom navigation bar and safety
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCancel(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar Cita?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(bookingsProvider.notifier).cancel(booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita cancelada con éxito')),
        );
        context.goNamed(RouteNames.home);
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(102),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
