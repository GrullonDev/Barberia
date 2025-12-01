import 'package:flutter/material.dart';
import 'package:barberia/common/design_tokens.dart';

/// Simple service summary card for grid selection.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
    super.key,
    this.selected = false,
  });

  final String title;
  final String subtitle; // e.g. "30 min"
  final String price; // formatted price
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(final BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: selected ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withAlpha(12)
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.outlineDark : AppColors.outline),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? AppShadows.medium : AppShadows.soft,
          ),
          padding: EdgeInsets.all(selected ? AppSpacing.m : AppSpacing.m - 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: selected ? 17 : 16,
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: isDark ? AppColors.secondary : AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.secondary : AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.secondaryContainer
                      : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
                child: Text(
                  price,
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.onSecondaryContainer
                        : AppColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
