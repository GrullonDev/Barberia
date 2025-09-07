import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/booking/widgets/service_card.dart';

class ServiceSelectPage extends ConsumerWidget {
  const ServiceSelectPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (final BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.name,
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.durationMinutes} min · ${NumberFormat.currency(name: 'GTQ', symbol: 'Q').format(s.price)}',
                ),
                const SizedBox(height: 16),
                Text(
                  'Descripción del servicio no disponible todavía. Aquí podrías agregar info adicional, recomendaciones o cuidados.',
                  style: Theme.of(
                    ctx,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(bookingDraftProvider.notifier).setService(s);
                    Navigator.of(ctx).pop();
                    context.goNamed(RouteNames.calendar);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Elegir y continuar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Servicio')),
      body: asyncServices.when(
        loading: () => const _ServicesGridSkeleton(),
        error: (final Object e, final StackTrace st) =>
            const Center(child: Text('Error cargando servicios')),
        data: (final List<Service> services) => services.isEmpty
            ? const Center(child: Text('No hay servicios disponibles'))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: services.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (final BuildContext _, final int i) {
                  final Service s = services[i];
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
