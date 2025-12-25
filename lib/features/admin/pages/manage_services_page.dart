import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import 'package:barberia/features/admin/pages/add_edit_service_page.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/common/design_tokens.dart';

class ManageServicesPage extends ConsumerWidget {
  const ManageServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Service>> servicesAsync = ref.watch(
      servicesAsyncProvider,
    );
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GESTIONAR SERVICIOS'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddEditServicePage()));
        },
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('NUEVO SERVICIO'),
      ),
      body: servicesAsync.when(
        data: (List<Service> services) {
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 64,
                    color: cs.secondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay servicios registrados',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (BuildContext context, int index) {
              final Service service = services[index];
              return _ServiceListTile(service: service, ref: ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace stack) =>
            Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ServiceListTile extends StatelessWidget {
  final Service service;
  final WidgetRef ref;

  const _ServiceListTile({required this.service, required this.ref});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.cut, color: cs.primary),
        ),
        title: Text(
          service.name,
          style: txt.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${NumberFormat.currency(name: 'GTQ', symbol: 'Q').format(service.price)} • ${service.durationMinutes} min',
            style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: cs.primary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditServicePage(service: service),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () async {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text('Eliminar Servicio'),
                    content: Text(
                      '¿Seguro que deseas eliminar "${service.name}"?',
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Eliminar'),
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (service.id != null) {
                    await ref
                        .read(serviceRepositoryProvider)
                        .deleteService(service.id!);
                    ref.invalidate(servicesAsyncProvider);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
