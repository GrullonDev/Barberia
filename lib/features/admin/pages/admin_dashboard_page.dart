import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/admin/pages/manage_services_page.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null)
            Text(
              'Bienvenido, ${user.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          const SizedBox(height: 20),
          _AdminCard(
            icon: Icons.cut,
            title: 'Gestionar Servicios',
            subtitle: 'Agregar, editar o eliminar servicios',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageServicesPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          // Placeholder for generic booking management if needed
          _AdminCard(
            icon: Icons.calendar_today,
            title: 'Ver Todas las Reservas',
            subtitle: 'Lista completa de citas (Próximamente)',
            onTap: () {
              // Navigation to admin bookings view
            },
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
