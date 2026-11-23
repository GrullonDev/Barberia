import 'package:barberia/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';
import 'package:barberia/core/providers/config_provider.dart';

class HomeFooter extends ConsumerWidget {
  const HomeFooter({super.key});

  static const _linkKeys = [
    'privacy_policy',
    'terms_of_service',
    'careers',
    'contact',
    'staff_access',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(
              top: BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: isMobile
                ? AppSpacing.marginMobile
                : AppSpacing.marginDesktop,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.containerMax,
              ),
              child: isMobile
                  ? _buildMobile(context, l10n)
                  : _buildDesktop(context, l10n),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktop(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Logo and Copyright
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LUXE & BLADE',
                style: AppTextStyles.headlineSm.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.04 * 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.get('all_rights_reserved'),
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        // Right side: Links
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            children: _linkKeys.map((key) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: _FooterLink(
                  label: l10n.get(key),
                  onTap: () => _handleFooterLink(context, key, l10n),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          'LUXE & BLADE',
          style: AppTextStyles.headlineSm.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.center,
          children: _linkKeys.map((key) {
            return _FooterLink(
              label: l10n.get(key),
              onTap: () => _handleFooterLink(context, key, l10n),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.get('all_rights_reserved'),
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _handleFooterLink(
    BuildContext context,
    String key,
    AppLocalizations l10n,
  ) async {
    switch (key) {
      case 'staff_access':
        context.go('/login');
        return;
      case 'contact':
        final uri = Uri(
          scheme: 'mailto',
          path: 'hello@luxeandblade.com',
          queryParameters: {
            'subject': l10n.languageCode == 'es'
                ? 'Consulta desde la web'
                : 'Website inquiry',
          },
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        }
        if (!context.mounted) return;
        _showFooterDialog(
          context,
          l10n.get('contact'),
          l10n.languageCode == 'es'
              ? 'Escribenos a hello@luxeandblade.com o reserva tu cita desde la web.'
              : 'Email us at hello@luxeandblade.com or book your appointment online.',
        );
        return;
      case 'privacy_policy':
        _showFooterDialog(
          context,
          l10n.get('privacy_policy'),
          l10n.languageCode == 'es'
              ? 'Usamos tus datos solo para procesar reservas, confirmar citas y dar seguimiento al servicio. El acceso operativo queda limitado al personal autorizado.'
              : 'We use your information only to process bookings, confirm appointments, and follow up on service. Operational access is limited to authorized staff.',
        );
        return;
      case 'terms_of_service':
        _showFooterDialog(
          context,
          l10n.get('terms_of_service'),
          l10n.languageCode == 'es'
              ? 'Las reservas dependen de disponibilidad real. El negocio puede confirmar, actualizar o cancelar una cita si existe conflicto operativo.'
              : 'Bookings depend on real availability. The shop may confirm, update, or cancel an appointment if an operational conflict exists.',
        );
        return;
      case 'careers':
        _showFooterDialog(
          context,
          l10n.get('careers'),
          l10n.languageCode == 'es'
              ? 'Para oportunidades de trabajo, envia tu perfil a careers@luxeandblade.com.'
              : 'For career opportunities, send your profile to careers@luxeandblade.com.',
        );
        return;
    }
  }

  void _showFooterDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap ?? () {},
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
    );
  }
}
