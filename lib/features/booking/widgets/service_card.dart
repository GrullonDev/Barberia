import 'package:flutter/material.dart';

import 'package:barberia/features/booking/data/mock_models.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({required this.service, super.key, this.onTap});

  final Service service;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: ListTile(
      title: Text(service.name),
      subtitle: Text(service.description),
      trailing: Text('\$${service.price}'),
      onTap: onTap,
    ),
  );
}
