import 'package:flutter/material.dart';

import 'package:barberia/features/booking/data/mock_models.dart';

class BookingSummarySheet extends StatelessWidget {
  const BookingSummarySheet({super.key, this.service, this.barber, this.slot});
  final Service? service;
  final Barber? barber;
  final Slot? slot;

  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Resumen de Reserva',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (service != null) ...<Widget>[
          Text('Servicio: ${service!.name}'),
          Text('Precio: \$${service!.price}'),
        ],
        if (barber != null) ...<Widget>[
          const SizedBox(height: 8),
          Text('Barbero: ${barber!.name}'),
        ],
        if (slot != null) ...<Widget>[
          const SizedBox(height: 8),
          Text('Fecha: ${slot!.dateTime.toLocal()}'),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
