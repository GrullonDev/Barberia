import 'package:barberia/features/auth/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/app/router.dart';
import 'package:barberia/common/design_tokens.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(authStateProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No has iniciado sesión')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          _ProfileItem(
            icon: Icons.person,
            label: 'Nombre de Usuario',
            value: user.name,
          ),
          _ProfileItem(
            icon: Icons.security,
            label: 'Rol',
            value: user.role == UserRole.admin ? 'Administrador' : 'Cliente',
            showDivider: false,
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.goNamed(RouteNames.login);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 60,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
