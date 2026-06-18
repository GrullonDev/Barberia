import 'package:barberia/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        Column(
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
        // Right side: Links
        Row(
          mainAxisSize: MainAxisSize.min,
          children: _linkKeys.map((key) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: _FooterLink(
                label: l10n.get(key),
                onTap: key == 'staff_access'
                    ? () => context.go('/login')
                    : null,
              ),
            );
          }).toList(),
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
              onTap: key == 'staff_access' ? () => context.go('/login') : null,
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
