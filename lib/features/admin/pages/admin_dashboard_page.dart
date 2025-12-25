import 'package:barberia/features/admin/pages/all_bookings_page.dart';
import 'package:barberia/features/admin/pages/manage_barbers_page.dart';
import 'package:barberia/features/admin/pages/manage_services_page.dart';
import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(authStateProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    // Real Stats Data
    final List<Booking> bookings = ref.watch(bookingsProvider);
    final AsyncValue<List<Service>> servicesAsync = ref.watch(
      servicesAsyncProvider,
    );

    // Calculate Today's Stats
    final DateTime today = DateTime.now();
    final List<Booking> todayBookings = bookings.where((Booking b) {
      return b.dateTime.year == today.year &&
          b.dateTime.month == today.month &&
          b.dateTime.day == today.day &&
          b.status != BookingStatus.canceled;
    }).toList();

    double estimatedRevenue = 0;
    if (servicesAsync.valueOrNull != null) {
      final List<Service> services = servicesAsync.valueOrNull!;
      for (final Booking booking in todayBookings) {
        final Service service = services.firstWhere(
          (Service s) => s.id == booking.serviceId,
          orElse: () => const Service(
            id: -1,
            name: '',
            price: 0,
            durationMinutes: 0,
            category: ServiceCategory.hair,
          ),
        );
        estimatedRevenue += service.price;
      }
    }

    final String revenueFormatted = NumberFormat.compactCurrency(
      symbol: 'Q',
    ).format(estimatedRevenue);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Panel Administrativo',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      cs.surface,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authStateProvider.notifier).logout(),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (user != null)
                    Text(
                      'Hola, ${user.name}',
                      style: txt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Aquí tienes el resumen de hoy.',
                    style: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  _OverviewSection(
                    todayCount: todayBookings.length.toString(),
                    revenue: revenueFormatted,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Gestión Rápida',
                    style: txt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AdminActionCard(
                    icon: Icons.content_cut,
                    title: 'Gestionar Servicios',
                    subtitle: 'Agregar, editar o eliminar servicios',
                    color: cs.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageServicesPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _AdminActionCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Agenda Completa',
                    subtitle: 'Ver todas las citas programadas',
                    color: const Color(0xFF3B82F6), // Blue
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AllBookingsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _AdminActionCard(
                    icon: Icons.people_outline,
                    title: 'Barberos',
                    subtitle: 'Gestionar equipo de trabajo',
                    color: const Color(0xFF10B981), // Emerald
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageBarbersPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final String todayCount;
  final String revenue;

  const _OverviewSection({required this.todayCount, required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            label: 'Citas Hoy',
            value: todayCount,
            icon: Icons.calendar_today,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Ingresos Est.',
            value: revenue,
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
