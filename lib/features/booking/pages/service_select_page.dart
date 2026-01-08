import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/booking/widgets/service_card.dart';
import 'package:barberia/l10n/app_localizations.dart';
import 'package:barberia/common/utils/responsive_helper.dart';

class ServiceSelectPage extends ConsumerWidget {
  const ServiceSelectPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final S tr = S.of(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<List<Service>> asyncServices = ref.watch(
      servicesAsyncProvider,
    );
    final BookingDraft draft = ref.watch(bookingDraftProvider);

    Future<void> showDetails(final Service s) async {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (final BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: ResponsiveHelper.getResponsivePadding(context),
              right: ResponsiveHelper.getResponsivePadding(context),
              top: 8,
              bottom:
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).padding.bottom +
                  ResponsiveHelper.getSpacing(context, mobile: 32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.content_cut,
                        color: cs.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            s.name,
                            style: Theme.of(ctx).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily:
                                      GoogleFonts.montserrat().fontFamily,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.durationMinutes} min • ${NumberFormat.currency(name: 'GTQ', symbol: 'Q').format(s.price)}',
                            style: Theme.of(ctx).textTheme.titleMedium
                                ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                if (s.extendedDescription != null) ...<Widget>[
                  Text(
                    'Descripción',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.extendedDescription!,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      ref.read(bookingDraftProvider.notifier).setService(s);
                      Navigator.of(ctx).pop();
                      context.goNamed(RouteNames.calendar);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: Text(
                      tr.service_choose_and_continue.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
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
                padding: EdgeInsets.fromLTRB(
                  ResponsiveHelper.getResponsivePadding(context),
                  12,
                  ResponsiveHelper.getResponsivePadding(context),
                  8,
                ),
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
                    padding: EdgeInsets.only(
                      left: ResponsiveHelper.getResponsivePadding(context),
                      right: ResponsiveHelper.getResponsivePadding(context),
                      top: ResponsiveHelper.getResponsivePadding(context),
                      bottom:
                          MediaQuery.of(context).padding.bottom +
                          80, // Space for navigation bar
                    ),
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveHelper.getGridColumns(context),
                      mainAxisSpacing: ResponsiveHelper.getSpacing(
                        context,
                        mobile: 16,
                      ),
                      crossAxisSpacing: ResponsiveHelper.getSpacing(
                        context,
                        mobile: 16,
                      ),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
            width: 1.5,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ServicesGridSkeleton extends StatelessWidget {
  const _ServicesGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getGridColumns(context),
        crossAxisSpacing: ResponsiveHelper.getSpacing(context, mobile: 16),
        mainAxisSpacing: ResponsiveHelper.getSpacing(context, mobile: 16),
        childAspectRatio: 0.95,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
