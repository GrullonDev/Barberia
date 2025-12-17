import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        children: <Widget>[
          const SizedBox(height: 8),
          _buildSectionHeader(context, 'Cuenta'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: 'Perfil',
            subtitle: 'Gestionar datos personales',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_none,
            title: 'Notificaciones',
            trailing: Switch.adaptive(value: true, onChanged: (bool v) {}),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: 'Seguridad',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Preferencias'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Idioma',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Español',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
              ],
            ),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Modo Oscuro',
            trailing: Switch.adaptive(value: false, onChanged: (bool v) {}),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Ayuda'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Centro de Ayuda',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'Acerca de',
            subtitle: 'Versión 1.0.0',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            iconColor: cs.error,
            textColor: cs.error,
            onTap: () {},
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(final BuildContext context, final String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    final BuildContext context, {
    required final IconData icon,
    required final String title,
    final String? subtitle,
    final Widget? trailing,
    final VoidCallback? onTap,
    final Color? iconColor,
    final Color? textColor,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? cs.primary).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? cs.primary, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor ?? cs.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              )
            : null,
        trailing:
            trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right, color: cs.onSurfaceVariant)
                : null),
      ),
    );
  }
}
