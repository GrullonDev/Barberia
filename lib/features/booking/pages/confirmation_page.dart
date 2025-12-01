import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/common/config/location_config.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/l10n/app_localizations.dart';

class ConfirmationPage extends ConsumerStatefulWidget {
  const ConfirmationPage({super.key});

  @override
  ConsumerState<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends ConsumerState<ConfirmationPage> {
  Booking?
  _booking; // Persist booking so it doesn't regenerate with new id on rebuilds.
  String? _qrData; // Will store a maps URL so scanners open location directly.
  bool _enqueued = false;

  void _ensureBookingScheduled() {
    if (_enqueued || _booking == null) {
      return;
    }
    _enqueued = true;
    // Schedule addition after build frame to avoid modifying provider in build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final List<Booking> current = ref.read(bookingsProvider);
      if (!current.any((final Booking b) => b.id == _booking!.id)) {
        ref.read(bookingsProvider.notifier).add(_booking!);
        // Limpiar borrador para siguiente flujo.
        ref.read(bookingDraftProvider.notifier).reset();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize booking once when dependencies available.
    if (_booking == null) {
      final BookingDraft draft = ref.read(bookingDraftProvider);
      if (draft.service != null &&
          draft.dateTime != null &&
          draft.name != null &&
          (draft.phone != null || draft.email != null)) {
        _booking = Booking(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          service: draft.service!,
          dateTime: draft.dateTime!,
          customerName: draft.name!,
          customerPhone: draft.phone,
          customerEmail: draft.email,
          notes: draft.notes,
        );
        // Build a Google Maps URL so external scanners open the location directly.
        // Also embed appointment metadata in the fragment for potential future mini-landing usage.
        const String address = 'Av. Principal 123, Ciudad';
        // Real test coordinates provided by user (can later be moved to config or backend):
        const double lat = 14.503056; // LAT
        const double lng = -90.577228; // LNG
        final String encodedAddress = Uri.encodeComponent(address);
        final String baseMapsUrl =
            'https://www.google.com/maps/search/?api=1&query=$encodedAddress&ll=$lat,$lng';
        final String fragment =
            'appt=${_booking!.id}&svc=${Uri.encodeComponent(_booking!.service.name)}&dt=${Uri.encodeComponent(_booking!.dateTime.toIso8601String())}';
        _qrData = '$baseMapsUrl#$fragment';
        _ensureBookingScheduled();
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final S tr = S.of(context);
    if (_booking == null) {
      return Scaffold(body: Center(child: Text(tr.confirm_incomplete)));
    }
    final Booking booking = _booking!;
    final String qrData = _qrData!; // maps link encoded in QR
    String two(int v) => v.toString().padLeft(2, '0');
    final DateTime start = booking.dateTime;
    final DateTime end = booking.endTime;
    final String dateStr =
        '${two(start.day)}/${two(start.month)}/${start.year}';
    final String timeRange =
        '${two(start.hour)}:${two(start.minute)} - ${two(end.hour)}:${two(end.minute)}';
    final int durMin = booking.service.durationMinutes;

    final ColorScheme cs = Theme.of(context).colorScheme;
    const String address = LocationConfig.address;
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: cs.surfaceContainerHighest,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              booking.service.name,
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
                              if (mounted) {
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on),
                        title: const Text(address),
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
                        onPressed: null, // deshabilitado en demo
                        icon: const Icon(Icons.edit_calendar),
                        label: Text(tr.appointment_rebook_soon),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: null, // deshabilitado en demo
                        icon: const Icon(Icons.cancel),
                        label: Text(tr.appointment_cancel_soon),
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
                        onPressed: () async {
                          // Avoid using BuildContext after awaits except for localization already captured.
                          final String subject =
                              tr.confirm_add_calendar_subject;
                          final String body = tr.confirm_add_calendar_body;
                          final String ics = booking.toIcsString();
                          final Directory tempDir =
                              await getTemporaryDirectory();
                          final String path =
                              '${tempDir.path}/cita-${booking.id}.ics';
                          final File icsFile = File(path);
                          await icsFile.writeAsString(
                            ics,
                          ); // mimeTypes is not a valid parameter for shareXFiles
                          await Share.shareXFiles(
                            <XFile>[XFile(path)],
                            subject: subject,
                            text: body,
                          );
                        },
                        icon: const Icon(Icons.event_available),
                        label: Text(tr.confirm_add_calendar),
                      ),
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
