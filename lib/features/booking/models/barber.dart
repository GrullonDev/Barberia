/// Seniority tier shown as a badge on the barber-selection cards.
enum BarberLevel { master, senior, elite }

extension BarberLevelLabel on BarberLevel {
  String get label => switch (this) {
    BarberLevel.master => 'Maestro Barbero',
    BarberLevel.senior => 'Barbero Senior',
    BarberLevel.elite => 'Estilista Elite',
  };

  String get badge => switch (this) {
    BarberLevel.master => 'Maestro',
    BarberLevel.senior => 'Senior',
    BarberLevel.elite => 'Elite',
  };
}

/// A barber that can be selected as part of the booking flow.
class Barber {
  const Barber({
    required this.id,
    required this.name,
    required this.level,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
  });

  final String id;
  final String name;
  final BarberLevel level;
  final String specialty;
  final double rating;
  final int reviewCount;
}

const List<Barber> mockBarbers = <Barber>[
  Barber(
    id: 'julian-vance',
    name: 'Julian Vance',
    level: BarberLevel.master,
    specialty: 'Especialista en cortes clásicos y afeitado a navaja',
    rating: 4.9,
    reviewCount: 312,
  ),
  Barber(
    id: 'marcus-reed',
    name: 'Marcus Reed',
    level: BarberLevel.senior,
    specialty: 'Experto en degradados modernos y diseño de barba',
    rating: 4.8,
    reviewCount: 248,
  ),
  Barber(
    id: 'dorian-grey',
    name: 'Dorian Grey',
    level: BarberLevel.elite,
    specialty: 'Estilos vanguardistas y coloración de precisión',
    rating: 5,
    reviewCount: 187,
  ),
];
