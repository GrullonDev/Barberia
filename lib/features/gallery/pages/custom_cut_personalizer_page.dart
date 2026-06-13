import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/common/widgets/gentleman_button.dart';
import 'package:barberia/common/widgets/gentleman_footer.dart';
import 'package:barberia/common/widgets/image_placeholder.dart';
import 'package:barberia/common/widgets/luxury_section_header.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/gallery/models/custom_cut_options.dart';
import 'package:barberia/features/gallery/models/hair_style.dart';

class CustomCutPersonalizerPage extends ConsumerStatefulWidget {
  const CustomCutPersonalizerPage({super.key, this.initialStyle});

  final HairStyle? initialStyle;

  @override
  ConsumerState<CustomCutPersonalizerPage> createState() =>
      _CustomCutPersonalizerPageState();
}

class _CustomCutPersonalizerPageState
    extends ConsumerState<CustomCutPersonalizerPage> {
  late CutBase _base;
  double _topLengthCm = 5;
  FadeType _fade = FadeType.mid;
  BeardDetail _beard = BeardDetail.lightStubble;

  @override
  void initState() {
    super.initState();
    _base = widget.initialStyle?.suggestedBase ?? CutBase.modern;
  }

  void _confirmAndBook() {
    final String summary =
        'Base: ${_base.label} • Largo: ${_topLengthCm.toStringAsFixed(0)} cm • '
        '${_fade.label} • Barba: ${_beard.label}';
    final Service customService = Service(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Estilo Personalizado',
      durationMinutes: 45,
      price: 180,
      category: ServiceCategory.hair,
      extendedDescription: summary,
    );
    ref.read(bookingDraftProvider.notifier).setService(customService);
    context.goNamed(RouteNames.barberSelect);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Personalizar Corte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        children: <Widget>[
          const LuxurySectionHeader(
            title: 'Custom Cut Personalizer',
            subtitle:
                'Diseña tu corte ideal eligiendo cada detalle. Nuestros '
                'barberos darán vida a tu visión.',
          ),
          const SizedBox(height: 24),

          // --- Live preview ---
          Stack(
            children: <Widget>[
              ImagePlaceholder(
                icon: _base.icon,
                height: 220,
                width: double.infinity,
                iconSize: 64,
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    _PreviewChip(label: 'ESTILO: ${_base.label}'),
                    _PreviewChip(label: _fade.label.toUpperCase()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Tu Estilo Gentleman', style: txt.titleMedium),
                const SizedBox(height: 12),
                _SummaryRow(label: 'Base', value: _base.label),
                _SummaryRow(
                  label: 'Largo de arriba',
                  value: '${_topLengthCm.toStringAsFixed(0)} cm',
                ),
                _SummaryRow(label: 'Degradado', value: _fade.label),
                _SummaryRow(label: 'Barba', value: _beard.label),
                const SizedBox(height: 20),
                GentlemanButton(
                  label: 'Confirmar y Agendar',
                  onPressed: _confirmAndBook,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- Choose your base ---
          Text('Elige tu Base', style: txt.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              for (final CutBase base in CutBase.values) ...<Widget>[
                Expanded(
                  child: _BaseOptionCard(
                    base: base,
                    selected: _base == base,
                    onTap: () => setState(() => _base = base),
                  ),
                ),
                if (base != CutBase.values.last) const SizedBox(width: 12),
              ],
            ],
          ),
          const SizedBox(height: 32),

          // --- Largo de arriba ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Largo de Arriba', style: txt.titleLarge),
              Text(
                '${_topLengthCm.toStringAsFixed(0)} cm',
                style: txt.titleMedium?.copyWith(color: cs.primary),
              ),
            ],
          ),
          Slider(
            value: _topLengthCm,
            min: 1,
            max: 10,
            divisions: 9,
            label: '${_topLengthCm.toStringAsFixed(0)} cm',
            onChanged: (final double v) => setState(() => _topLengthCm = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Corto',
                style: txt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                'Largo',
                style: txt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Tipo de degradado ---
          Text('Tipo de Degradado', style: txt.titleLarge),
          const SizedBox(height: 12),
          for (final FadeType type in FadeType.values)
            _FadeOptionRow(
              type: type,
              selected: _fade == type,
              onTap: () => setState(() => _fade = type),
            ),
          const SizedBox(height: 24),

          // --- Detalle de barba ---
          Text('Detalle de Barba', style: txt.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<BeardDetail>(
            initialValue: _beard,
            items: <DropdownMenuItem<BeardDetail>>[
              for (final BeardDetail detail in BeardDetail.values)
                DropdownMenuItem<BeardDetail>(
                  value: detail,
                  child: Text(detail.label),
                ),
            ],
            onChanged: (final BeardDetail? v) {
              if (v != null) {
                setState(() => _beard = v);
              }
            },
          ),
          const SizedBox(height: 32),

          // --- Info cards ---
          const Row(
            children: <Widget>[
              Expanded(
                child: _InfoCard(
                  icon: Icons.military_tech,
                  title: 'Prestigio &\nPrecisión',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.schedule,
                  title: '45\nMinutos',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.local_bar,
                  title: 'Bebida de\nCortesía',
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const GentlemanFooter(),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.label});
  final String label;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cs.primary.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          Text(value, style: txt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BaseOptionCard extends StatelessWidget {
  const _BaseOptionCard({
    required this.base,
    required this.selected,
    required this.onTap,
  });

  final CutBase base;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              base.icon,
              color: selected ? cs.primary : cs.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              base.label,
              style: txt.labelLarge?.copyWith(
                color: selected ? cs.primary : cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FadeOptionRow extends StatelessWidget {
  const _FadeOptionRow({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final FadeType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    type.label,
                    style: txt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.description,
                    style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: cs.primary, size: 26),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: txt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
