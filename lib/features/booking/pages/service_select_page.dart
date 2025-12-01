import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/booking/widgets/service_card.dart';
import 'package:barberia/l10n/app_localizations.dart';
import 'package:barberia/common/design_tokens.dart';

class ServiceSelectPage extends ConsumerWidget {
  const ServiceSelectPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final S tr = S.of(context);
    final AsyncValue<List<Service>> asyncServices = ref.watch(
      servicesAsyncProvider,
    );
    final BookingDraft draft = ref.watch(bookingDraftProvider);

    Future<void> showDetails(final Service s) async {
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        builder: (final BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.l,
              right: AppSpacing.l,
              top: AppSpacing.s,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.name,
                  style: AppTypography.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  '${s.durationMinutes} min · ${NumberFormat.currency(name: 'GTQ', symbol: 'Q').format(s.price)}',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                if (s.extendedDescription != null)
                  Text(
                    s.extendedDescription!,
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      color: isDark ? AppColors.secondary : AppColors.secondary,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: AppSpacing.l),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.secondaryContainer
                        : AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    border: Border.all(
                      color: isDark ? AppColors.outlineDark : AppColors.outline,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppColors.onSecondaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          tr.service_policy_rebook,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                if (s.extendedDescription == null) ...[
                  Text(
                    'Descripción del servicio no disponible todavía. Aquí podrías agregar info adicional, recomendaciones o cuidados.',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.secondary : AppColors.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(bookingDraftProvider.notifier).setService(s);
                      Navigator.of(ctx).pop();
                      context.goNamed(RouteNames.calendar);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.l),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      tr.service_choose_and_continue,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.secondary
                          : AppColors.secondary,
                    ),
                    child: Text(tr.cancel),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    final StateProvider<ServiceCategory?> categoryFilterProvider =
        StateProvider<ServiceCategory?>((final Ref _) => null);
    final ServiceCategory? selectedCat = ref.watch(categoryFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr.home_title)),
      body: asyncServices.when(
        loading: () => const _ServicesGridSkeleton(),
        error: (final Object e, final StackTrace st) =>
            const Center(child: Text('Error cargando servicios')),
        data: (final List<Service> services) {
          final List<Service> filtered = selectedCat == null
              ? services
              : services
                    .where((final Service s) => s.category == selectedCat)
                    .toList();
          return Column(
            children: <Widget>[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: <Widget>[
                    _CategoryChip(
                      label: tr.services_filter_all,
                      selected: selectedCat == null,
                      onTap: () =>
                          ref.read(categoryFilterProvider.notifier).state =
                              null,
                    ),
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: tr.services_filter_hair,
                      selected: selectedCat == ServiceCategory.hair,
                      onTap: () =>
                          ref.read(categoryFilterProvider.notifier).state =
                              ServiceCategory.hair,
                    ),
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: tr.services_filter_beard,
                      selected: selectedCat == ServiceCategory.beard,
                      onTap: () =>
                          ref.read(categoryFilterProvider.notifier).state =
                              ServiceCategory.beard,
                    ),
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: tr.services_filter_combo,
                      selected: selectedCat == ServiceCategory.combo,
                      onTap: () =>
                          ref.read(categoryFilterProvider.notifier).state =
                              ServiceCategory.combo,
                    ),
                    _CategoryChip(
                      label: tr.services_filter_facial,
                      selected: selectedCat == ServiceCategory.facial,
                      onTap: () =>
                          ref.read(categoryFilterProvider.notifier).state =
                              ServiceCategory.facial,
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              if (filtered.isEmpty)
                const Expanded(
                  child: Center(child: Text('No hay servicios disponibles')),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.95,
                        ),
                    itemBuilder: (final BuildContext _, final int i) {
                      final Service s = filtered[i];
                      final bool isSelected = draft.service?.id == s.id;
                      return ServiceCard(
                        title: s.name,
                        subtitle: '${s.durationMinutes} min',
                        price: NumberFormat.currency(
                          name: 'GTQ',
                          symbol: 'Q',
                        ).format(s.price),
                        selected: isSelected,
                        onTap: () => showDetails(s),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Skeleton shimmer grid while services load.
class _ServicesGridSkeleton extends StatefulWidget {
  const _ServicesGridSkeleton();

  @override
  State<_ServicesGridSkeleton> createState() => _ServicesGridSkeletonState();
}

class _ServicesGridSkeletonState extends State<_ServicesGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, final int i) => _Shimmer(
        controller: _controller,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(64),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _block(height: 16, width: 100, cs: cs),
              const SizedBox(height: 8),
              _block(height: 12, width: 60, cs: cs),
              const Spacer(),
              _block(height: 16, width: 50, cs: cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block({
    required final double height,
    required final double width,
    required final ColorScheme cs,
  }) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: cs.onSurface.withAlpha(18),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.l),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.outlineDark : AppColors.outline),
          ),
          boxShadow: selected ? AppShadows.soft : [],
        ),
        child: Text(
          label,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.onPrimary
                : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Basic manual shimmer (avoids external deps).
class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.child, required this.controller});
  final Widget child;
  final AnimationController controller;

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, final Widget? w) {
        return ShaderMask(
          shaderCallback: (final Rect rect) {
            return LinearGradient(
              begin: Alignment(-1 - 0.3 + controller.value * 2, 0),
              end: const Alignment(1, 0),
              colors: <Color>[
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.05),
              ],
              stops: const <double>[0.1, 0.5, 0.9],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: w,
        );
      },
      child: child,
    );
  }
}
