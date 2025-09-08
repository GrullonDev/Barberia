import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

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
    if (_booking == null) {
      return const Scaffold(body: Center(child: Text('Reserva incompleta')));
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
    const String address = 'Av. Principal 123, Ciudad';
    const double lat = 14.503056; // Keep in sync with QR
    const double lng = -90.577228;
    final String mapsBase =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}&ll=$lat,$lng';
    final Uri mapsUri = Uri.parse(mapsBase);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación de Reserva')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                            'APPT-${booking.id.substring(booking.id.length - 4)}',
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
                          label:
                              'Código QR de ubicación con metadatos de la cita. Escanea para abrir la dirección en Maps.',
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
                          label: const Text('Copiar enlace'),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: qrData),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enlace copiado')),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Compartir'),
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
                      subtitle: const Text('Abrir en Maps'),
                      onTap: () async {
                        if (await canLaunchUrl(mapsUri)) {
                          await launchUrl(
                            mapsUri,
                            mode: LaunchMode.externalApplication,
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
                      label: const Text('Reprogramar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: null, // deshabilitado en demo
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
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
                      label: const Text('Inicio'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final String ics = booking.toIcsString();
                        Share.share(ics, subject: 'Añadir a calendario (.ics)');
                      },
                      icon: const Icon(Icons.event_available),
                      label: const Text('Añadir al calendario'),
                    ),
                  ),
                ],
              ),
            ],
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
        color: cs.surfaceContainerHighest.withValues(alpha: .4),
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
