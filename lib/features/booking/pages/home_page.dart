import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/common/widgets/gentleman_button.dart';
import 'package:barberia/common/widgets/gentleman_footer.dart';
import 'package:barberia/common/widgets/image_placeholder.dart';
import 'package:barberia/common/widgets/luxury_section_header.dart';
import 'package:barberia/features/gallery/models/hair_style.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('THE GENTLEMAN'),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.goNamed(RouteNames.services),
            child: const Text('RESERVAR'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: <Widget>[
          // --- Hero ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Stack(
              children: <Widget>[
                const ImagePlaceholder(
                  icon: Icons.content_cut,
                  height: 360,
                  width: double.infinity,
                  borderRadius: 20,
                  iconSize: 72,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Maestría en cada corte, estilo en cada detalle',
                        style: txt.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Donde la tradición de la barbería clásica se '
                        'encuentra con la precisión moderna.',
                        style: txt.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          GentlemanButton(
                            label: 'Reservar Cita',
                            expand: false,
                            onPressed: () =>
                                context.goNamed(RouteNames.services),
                          ),
                          GentlemanButton(
                            label: 'Nuestros Servicios',
                            variant: GentlemanButtonVariant.secondary,
                            expand: false,
                            onPressed: () =>
                                context.goNamed(RouteNames.services),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Nuestros Servicios ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: LuxurySectionHeader(title: 'Nuestros Servicios'),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: <Widget>[
                _ServiceHighlightCard(
                  icon: Icons.content_cut,
                  title: 'Corte de Autor',
                  description:
                      'Un corte de precisión adaptado a tu estilo personal, '
                      'finalizado con un repaso de navaja.',
                  price: 'Desde Q150',
                ),
                SizedBox(height: 16),
                _ServiceHighlightCard(
                  icon: Icons.face_retouching_natural,
                  title: 'Ritual de Barba',
                  description:
                      'Diseño y arreglo de barba con toalla caliente, '
                      'aceites y bálsamos premium.',
                  price: 'Desde Q100',
                ),
                SizedBox(height: 16),
                _ServiceHighlightCard(
                  icon: Icons.spa,
                  title: 'Tratamiento Facial',
                  description:
                      'Limpieza facial revitalizante para complementar tu '
                      'imagen y cuidar tu piel.',
                  price: 'Desde Q120',
                ),
              ],
            ),
          ),

          // --- Galería de Estilos ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text('Galería de Estilos', style: txt.headlineSmall),
                TextButton(
                  onPressed: () => context.goNamed(RouteNames.gallery),
                  child: const Text('VER PORTAFOLIO'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: mockHairStyles.length.clamp(0, 4),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (final BuildContext _, final int i) {
                final HairStyle style = mockHairStyles[i];
                return GestureDetector(
                  onTap: () => context.goNamed(RouteNames.gallery),
                  child: ImagePlaceholder(
                    icon: style.icon,
                    width: 140,
                    height: 140,
                    iconSize: 36,
                  ),
                );
              },
            ),
          ),

          // --- ¿Por qué elegirnos? ---
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 40, 20, 24),
            child: LuxurySectionHeader(title: '¿Por qué elegirnos?'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: <Widget>[
                _FeatureBlock(
                  icon: Icons.workspace_premium,
                  title: 'Profesionalismo Incomparable',
                  description:
                      'Nuestros barberos son maestros de su oficio, con años '
                      'de experiencia y formación continua.',
                ),
                SizedBox(height: 24),
                _FeatureBlock(
                  icon: Icons.chair_alt,
                  title: 'Atmósfera Premium',
                  description:
                      'Un espacio diseñado para tu comodidad, donde cada '
                      'detalle invita a relajarte y disfrutar.',
                ),
                SizedBox(height: 24),
                _FeatureBlock(
                  icon: Icons.auto_awesome,
                  title: 'Productos de Élite',
                  description:
                      'Utilizamos únicamente productos de la más alta '
                      'calidad para el cuidado de tu cabello y piel.',
                ),
              ],
            ),
          ),

          // --- CTA banner ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    '¿Listo para elevar tu estilo?',
                    textAlign: TextAlign.center,
                    style: txt.headlineSmall?.copyWith(color: cs.onPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reserva tu cita hoy y experimenta el servicio que '
                    'mereces.',
                    textAlign: TextAlign.center,
                    style: txt.bodyMedium?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GentlemanButton(
                    label: 'Reservar Ahora',
                    variant: GentlemanButtonVariant.dark,
                    expand: false,
                    onPressed: () => context.goNamed(RouteNames.services),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
          const GentlemanFooter(),
        ],
      ),
    );
  }
}

class _ServiceHighlightCard extends StatelessWidget {
  const _ServiceHighlightCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
  });

  final IconData icon;
  final String title;
  final String description;
  final String price;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Container(
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
          Icon(icon, color: cs.primary, size: 32),
          const SizedBox(height: 16),
          Text(title, style: txt.titleMedium),
          const SizedBox(height: 8),
          Text(
            description,
            style: txt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                price,
                style: txt.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.goNamed(RouteNames.services),
                child: Text(
                  'DETALLES',
                  style: txt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureBlock extends StatelessWidget {
  const _FeatureBlock({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surfaceContainerHigh,
            border: Border.all(color: cs.primary, width: 1),
          ),
          child: Icon(icon, color: cs.primary, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: txt.titleMedium),
              const SizedBox(height: 6),
              Text(
                description,
                style: txt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
