import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/common/widgets/gentleman_button.dart';
import 'package:barberia/common/widgets/gentleman_footer.dart';
import 'package:barberia/common/widgets/image_placeholder.dart';
import 'package:barberia/common/widgets/luxury_section_header.dart';
import 'package:barberia/features/gallery/models/hair_style.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  StyleCategory? _selectedCategory;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    final List<HairStyle> filtered = _selectedCategory == null
        ? mockHairStyles
        : mockHairStyles
              .where(
                (final HairStyle s) => s.category == _selectedCategory,
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Galería')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        children: <Widget>[
          const LuxurySectionHeader(
            title: 'Nuestros Estilos de Firma',
            subtitle:
                'Explora nuestra colección curada de cortes y selecciona '
                'tu favorito para personalizarlo a tu medida.',
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _FilterChip(
                  label: 'Todos',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 10),
                for (final StyleCategory cat in StyleCategory.values) ...<Widget>[
                  _FilterChip(
                    label: cat.label,
                    selected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (final HairStyle style in filtered) ...<Widget>[
            _StyleCard(style: style),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  '¿Buscas algo exclusivo?',
                  textAlign: TextAlign.center,
                  style: txt.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Agenda una consulta personalizada con uno de nuestros '
                  'maestros barberos.',
                  textAlign: TextAlign.center,
                  style: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                GentlemanButton(
                  label: 'Reserva una Consulta',
                  onPressed: () => context.goNamed(RouteNames.services),
                ),
                const SizedBox(height: 12),
                GentlemanButton(
                  label: 'Ver Portafolio Completo',
                  variant: GentlemanButtonVariant.secondary,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const GentlemanFooter(),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.style});

  final HairStyle style;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ImagePlaceholder(
            icon: style.icon,
            badge: style.badge,
            height: 180,
            width: double.infinity,
            borderRadius: 0,
            iconSize: 56,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(style.name, style: txt.titleMedium),
                const SizedBox(height: 8),
                Text(
                  style.description,
                  style: txt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                GentlemanButton(
                  label: 'Personalizar Este Estilo',
                  variant: GentlemanButtonVariant.secondary,
                  onPressed: () => context.pushNamed(
                    RouteNames.personalize,
                    extra: style,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
