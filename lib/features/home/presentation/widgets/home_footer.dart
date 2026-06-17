import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  static const _links = [
    'Privacy Policy',
    'Terms of Service',
    'Careers',
    'Contact',
    'Staff Access',
  ];

  @override
  Widget build(BuildContext context) {
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
              child: isMobile ? _buildMobile(context) : _buildDesktop(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktop(BuildContext context) {
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
              '© 2026 LUXE & BLADE GENTLEMEN LOUNGE. ALL RIGHTS RESERVED.',
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
          children: _links.map((link) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: _FooterLink(
                label: link,
                onTap: link == 'Staff Access'
                    ? () => context.go('/login')
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context) {
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
          children: _links.map((link) {
            return _FooterLink(
              label: link,
              onTap: link == 'Staff Access' ? () => context.go('/login') : null,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '© 2026 LUXE & BLADE GENTLEMEN LOUNGE. ALL RIGHTS RESERVED.',
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
