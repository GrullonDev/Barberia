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

class ServiceSelectPage extends ConsumerWidget {
  const ServiceSelectPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final S tr = S.of(context);
    final AsyncValue<List<Service>> asyncServices = ref.watch(
      servicesAsyncProvider,
    );
    final BookingDraft draft = ref.watch(bookingDraftProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;

    Future<void> showDetails(final Service s) async {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (final BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.cut, color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            s.name,
                            style: Theme.of(ctx).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${s.durationMinutes} min • ${NumberFormat.currency(name: 'GTQ', symbol: 'Q').format(s.price)}',
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (s.extendedDescription != null) ...<Widget>[
                  Text(
                    'Detalles',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.extendedDescription!,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.secondaryContainer),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 24,
                        color: cs.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr.service_policy_rebook,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () {
                      ref.read(bookingDraftProvider.notifier).setService(s);
                      Navigator.of(ctx).pop();
                      context.goNamed(RouteNames.calendar);
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      tr.service_choose_and_continue,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      tr.cancel,
                      style: TextStyle(color: cs.secondary),
                    ),
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
            color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
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
      color: cs.onSurface.withValues(alpha: 0.07),
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: 1.5,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
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
