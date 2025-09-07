import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/common/utils/qr_signer.dart';
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
  String? _qrData;
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
        _qrData = QrSigner.buildSignedPayload(<String, Object?>{
          'id': _booking!.id,
          'svc': _booking!.service.id,
          'ts': _booking!.dateTime.toIso8601String(),
          'nm': _booking!.customerName,
        });
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
    final String qrData = _qrData!;
  String two(int v) => v.toString().padLeft(2, '0');
  final DateTime start = booking.dateTime;
  final DateTime end = booking.endTime;
  final String dateStr = '${two(start.day)}/${two(start.month)}/${start.year}';
  final String timeRange = '${two(start.hour)}:${two(start.minute)} - ${two(end.hour)}:${two(end.minute)}';
  final int durMin = booking.service.durationMinutes;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación de Reserva')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              booking.service.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('$dateStr  $timeRange'),
            const SizedBox(height: 16),
            QrImageView(data: qrData, size: 160),
            const SizedBox(height: 16),
            Text('Cliente: ${booking.customerName}'),
            if (booking.customerPhone != null)
              Text('Tel: ${booking.customerPhone}'),
            if (booking.customerEmail != null)
              Text('Email: ${booking.customerEmail}'),
            const SizedBox(height: 8),
            Text('Duración: $durMin min'),
            const Spacer(),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.goNamed(RouteNames.home),
                    child: const Text('Inicio'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final String ics = booking.toIcsString();
                      // ignore: deprecated_member_use
                      Share.share(ics, subject: 'Añadir a calendario');
                    },
                    child: const Text('Añadir al calendario'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
