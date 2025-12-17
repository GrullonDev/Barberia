import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/features/admin/pages/add_edit_service_page.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

class ManageServicesPage extends ConsumerWidget {
  const ManageServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Service>> servicesAsync = ref.watch(
      servicesAsyncProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Servicios')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddEditServicePage()));
        },
        child: const Icon(Icons.add),
      ),
      body: servicesAsync.when(
        data: (List<Service> services) {
          if (services.isEmpty) {
            return const Center(child: Text('No hay servicios.'));
          }
          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (BuildContext context, int index) {
              final Service service = services[index];
              return ListTile(
                title: Text(service.name),
                subtitle: Text(
                  '\$${service.price} - ${service.durationMinutes} min',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditServicePage(service: service),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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
                                child: const Text('Eliminar'),
                                onPressed: () => Navigator.pop(ctx, true),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(serviceRepositoryProvider)
                              .deleteService(service.id);
                          ref.invalidate(servicesAsyncProvider);
                        }
                      },
                    ),
                  ],
                ),
              );
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
