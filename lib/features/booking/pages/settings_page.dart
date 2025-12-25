import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:barberia/app/locale_controller.dart';
import 'package:barberia/app/router.dart';
import 'package:barberia/app/theme_controller.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeMode mode = ref.watch(themeControllerProvider).mode;
    final bool isDark = mode == ThemeMode.dark;
    final Locale currentLocale = ref.watch(localeControllerProvider);

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
            onTap: () => context.goNamed(RouteNames.profile),
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
            subtitle: 'Cambiar contraseña',
            onTap: () => _showChangePasswordDialog(context, ref),
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
                  currentLocale.languageCode == 'es' ? 'Español' : 'English',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
              ],
            ),
            onTap: () => _showLanguageSelector(context, ref, currentLocale),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Modo Oscuro',
            trailing: Switch.adaptive(
              value: isDark,
              onChanged: (bool v) {
                ref
                    .read(themeControllerProvider.notifier)
                    .setMode(v ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Ayuda'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Centro de Ayuda',
            onTap: () => _showHelpCenter(context),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'Acerca de',
            subtitle: 'Versión 1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 24),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            iconColor: cs.error,
            textColor: cs.error,
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
            },
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
        color: cs.surfaceContainerHigh.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? cs.primary).withValues(alpha: 0.1),
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

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final TextEditingController passCtrl = TextEditingController();
    final TextEditingController confirmCtrl = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (v) {
                  if (v != passCtrl.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                final currentUser = ref
                    .read(authRepositoryProvider)
                    .currentUser;
                if (currentUser != null) {
                  await ref
                      .read(authRepositoryProvider)
                      .updatePassword(currentUser.id, passCtrl.text);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contraseña actualizada con éxito'),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Español'),
              trailing: currentLocale.languageCode == 'es'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                ref
                    .read(localeControllerProvider.notifier)
                    .setLocale(const Locale('es'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: currentLocale.languageCode == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                ref
                    .read(localeControllerProvider.notifier)
                    .setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  void _showHelpCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Centro de Ayuda',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Problema con una cita'),
              subtitle: const Text('Contactar a la barbería'),
              onTap: () {
                Navigator.pop(ctx);
                _launchUrl(
                  'https://wa.me/1234567890',
                ); // Replace with actual number
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: const Text('Problema con la App'),
              subtitle: const Text('Contactar al desarrollador'),
              onTap: () {
                Navigator.pop(ctx);
                _launchUrl('mailto:support@barberia.com');
              },
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AboutDialog(
        applicationName: 'Barbería App',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(Icons.content_cut, size: 48),
        children: const [
          SizedBox(height: 16),
          Text(
            'Esta aplicación fue desarrollada para gestionar citas de barbería de manera eficiente.',
          ),
          SizedBox(height: 16),
          Text('Desarrollador: Jorge Grullon'),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch \$url');
    }
  }
}
