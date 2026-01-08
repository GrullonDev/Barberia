import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/common/design_tokens.dart';

// Prototype Model
class Barber {
  final String id;
  final String name;
  final String specialty;
  final bool isAvailable;

  Barber({
    required this.id,
    required this.name,
    required this.specialty,
    this.isAvailable = true,
  });

  Barber copyWith({String? name, String? specialty, bool? isAvailable}) {
    return Barber(
      id: id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

// In-memory State Notifier for Prototype
class BarbersNotifier extends StateNotifier<List<Barber>> {
  BarbersNotifier()
    : super(<Barber>[
        Barber(id: '1', name: 'Juan Pérez', specialty: 'Corte Clásico'),
        Barber(id: '2', name: 'Carlos Díaz', specialty: 'Barba & Fade'),
        Barber(id: '3', name: 'Ana Gómez', specialty: 'Coloración'),
      ]);

  void add(String name, String specialty) {
    if (name.isEmpty || specialty.isEmpty) return;
    state = <Barber>[
      ...state,
      Barber(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        specialty: specialty,
      ),
    ];
  }

  void toggleAvailability(String id) {
    state = <Barber>[
      for (final Barber barber in state)
        if (barber.id == id)
          barber.copyWith(isAvailable: !barber.isAvailable)
        else
          barber,
    ];
  }

  void remove(String id) {
    state = state.where((Barber b) => b.id != id).toList();
  }
}

final StateNotifierProvider<BarbersNotifier, List<Barber>> barbersProvider =
    StateNotifierProvider<BarbersNotifier, List<Barber>>((
      StateNotifierProviderRef<BarbersNotifier, List<Barber>> ref,
    ) {
      return BarbersNotifier();
    });

class ManageBarbersPage extends ConsumerWidget {
  const ManageBarbersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Barber> barbers = ref.watch(barbersProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GESTIONAR BARBEROS'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBarberDialog(context, ref),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.person_add),
        label: const Text('NUEVO BARBERO'),
        elevation: 4,
      ),
      body: barbers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 64,
                      color: cs.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No hay barberos registrados',
                    style: txt.titleMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega uno nuevo para comenzar',
                    style: txt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: barbers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (BuildContext context, int index) {
                final Barber barber = barbers[index];
                return _BarberCard(barber: barber);
              },
            ),
    );
  }

  void _showAddBarberDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController specialtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Agregar Barbero'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: specialtyController,
              decoration: const InputDecoration(
                labelText: 'Especialidad',
                prefixIcon: Icon(Icons.content_cut_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(barbersProvider.notifier)
                  .add(nameController.text, specialtyController.text);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _BarberCard extends ConsumerWidget {
  const _BarberCard({required this.barber});

  final Barber barber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Future feature: Edit barber
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  child: Text(
                    barber.name.isNotEmpty ? barber.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barber.name,
                        style: txt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          barber.specialty,
                          style: txt.bodySmall?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Switch(
                      value: barber.isAvailable,
                      activeColor: cs.primary,
                      onChanged: (_) => ref
                          .read(barbersProvider.notifier)
                          .toggleAvailability(barber.id),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: () => _confirmDelete(context, ref, barber),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Barber barber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar barbero?'),
        content: Text(
          'Estás a punto de eliminar a ${barber.name}. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(barbersProvider.notifier).remove(barber.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
