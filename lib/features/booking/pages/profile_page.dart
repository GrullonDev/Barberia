import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            // User Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.primary, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 2),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 14,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Juan Pérez',
                    style: txt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'juan.perez@example.com',
                    style: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  _ProfileMenuSection(
                    title: 'Cuenta',
                    children: <Widget>[
                      _ProfileMenuItem(
                        icon: Icons.person_outline,
                        title: 'Datos Personales',
                        onTap: () {},
                      ),
                      _ProfileMenuItem(
                        icon: Icons.history,
                        title: 'Mis Reservas',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ProfileMenuSection(
                    title: 'General',
                    children: <Widget>[
                      _ProfileMenuItem(
                        icon: Icons.notifications_none,
                        title: 'Notificaciones',
                        onTap: () {},
                      ),
                      _ProfileMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Configuración',
                        onTap: () {},
                      ),
                      _ProfileMenuItem(
                        icon: Icons.policy_outlined,
                        title: 'Políticas de Privacidad',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ProfileMenuItem(
                    icon: Icons.logout,
                    title: 'Cerrar Sesión',
                    textColor: cs.error,
                    iconColor: cs.error,
                    showTrailing: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuSection extends StatelessWidget {
  const _ProfileMenuSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.showTrailing = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? cs.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor ?? cs.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: textColor ?? cs.onSurface,
                  ),
                ),
              ),
              if (showTrailing)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
