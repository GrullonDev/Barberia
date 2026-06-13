import 'package:flutter/material.dart';

/// Category used to filter the style gallery.
enum StyleCategory { clasico, moderno, corto }

extension StyleCategoryLabel on StyleCategory {
  String get label => switch (this) {
    StyleCategory.clasico => 'Clásicos',
    StyleCategory.moderno => 'Modernos',
    StyleCategory.corto => 'Cortos',
  };
}

/// Base cut used as a starting point in the Custom Cut Personalizer.
enum CutBase { classic, modern, edgy }

extension CutBaseLabel on CutBase {
  String get label => switch (this) {
    CutBase.classic => 'Clásico',
    CutBase.modern => 'Moderno',
    CutBase.edgy => 'Audaz',
  };

  IconData get icon => switch (this) {
    CutBase.classic => Icons.face_retouching_natural,
    CutBase.modern => Icons.auto_awesome,
    CutBase.edgy => Icons.bolt,
  };
}

/// A signature style shown in the gallery, with a suggested starting point
/// for the Custom Cut Personalizer.
class HairStyle {
  const HairStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.suggestedBase,
    required this.icon,
    this.badge,
  });

  final String id;
  final String name;
  final String description;
  final StyleCategory category;
  final CutBase suggestedBase;
  final IconData icon;
  final String? badge;
}

const List<HairStyle> mockHairStyles = <HairStyle>[
  HairStyle(
    id: 'modern-fade',
    name: 'Fade Moderno',
    description:
        'Degradado limpio y preciso con un acabado de textura en la parte '
        'superior, ideal para un look contemporáneo y de bajo mantenimiento.',
    category: StyleCategory.moderno,
    suggestedBase: CutBase.modern,
    icon: Icons.content_cut,
    badge: 'Popular',
  ),
  HairStyle(
    id: 'pompadour',
    name: 'Pompadour Clásico',
    description:
        'Volumen elegante hacia atrás con los lados cortos, un clásico '
        'atemporal que transmite distinción.',
    category: StyleCategory.clasico,
    suggestedBase: CutBase.classic,
    icon: Icons.face,
    badge: 'Atemporal',
  ),
  HairStyle(
    id: 'buzz-cut',
    name: 'Buzz Cut',
    description:
        'Corte uniforme y muy corto en toda la cabeza, práctico, audaz y '
        'de mínimo mantenimiento.',
    category: StyleCategory.corto,
    suggestedBase: CutBase.edgy,
    icon: Icons.crop_square,
  ),
  HairStyle(
    id: 'executive',
    name: 'Corte Ejecutivo',
    description:
        'Un corte pulido y versátil que mantiene la longitud justa para '
        'peinar de forma profesional en cualquier ocasión.',
    category: StyleCategory.clasico,
    suggestedBase: CutBase.classic,
    icon: Icons.business_center,
  ),
  HairStyle(
    id: 'textured-crop',
    name: 'Crop Texturizado',
    description:
        'Flequillo desconectado con textura natural, un estilo moderno '
        'inspirado en las tendencias europeas.',
    category: StyleCategory.moderno,
    suggestedBase: CutBase.modern,
    icon: Icons.waves,
    badge: 'Tendencia',
  ),
  HairStyle(
    id: 'caesar-crop',
    name: 'Caesar Crop',
    description:
        'Corte corto y uniforme con flequillo recto, un equilibrio perfecto '
        'entre estilo clásico y practicidad moderna.',
    category: StyleCategory.corto,
    suggestedBase: CutBase.classic,
    icon: Icons.grid_on,
  ),
];
