class Service {
  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
  });
  final String id;
  final String name;
  final String description;
  final double price;
  final Duration duration;
}

class Barber {
  Barber({
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
  });
  final String id;
  final String name;
  final String specialty;
  final String imageUrl;
}

class Slot {
  Slot({required this.id, required this.dateTime, required this.isAvailable});
  final String id;
  final DateTime dateTime;
  final bool isAvailable;
}

class Appointment {
  Appointment({
    required this.id,
    required this.service,
    required this.barber,
    required this.slot,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
  });
  final String id;
  final Service service;
  final Barber barber;
  final Slot slot;
  final String clientName;
  final String clientPhone;
  final String clientEmail;
}

// Mock data
final List<Service> mockServices = <Service>[
  Service(
    id: '1',
    name: 'Corte de cabello',
    description: 'Corte moderno y estilizado',
    price: 25,
    duration: const Duration(minutes: 30),
  ),
  Service(
    id: '2',
    name: 'Afeitado',
    description: 'Afeitado tradicional con navaja',
    price: 15,
    duration: const Duration(minutes: 20),
  ),
];

final List<Barber> mockBarbers = <Barber>[
  Barber(
    id: '1',
    name: 'Carlos',
    specialty: 'Cortes modernos',
    imageUrl: 'https://example.com/barber1.jpg',
  ),
  Barber(
    id: '2',
    name: 'Miguel',
    specialty: 'Afeitados clásicos',
    imageUrl: 'https://example.com/barber2.jpg',
  ),
];

final List<Slot> mockSlots = <Slot>[
  Slot(
    id: '1',
    dateTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
    isAvailable: true,
  ),
  Slot(
    id: '2',
    dateTime: DateTime.now().add(const Duration(days: 1, hours: 11)),
    isAvailable: true,
  ),
];

final List<Appointment> mockAppointments = <Appointment>[
  Appointment(
    id: '1',
    service: mockServices[0],
    barber: mockBarbers[0],
    slot: mockSlots[0],
    clientName: 'Juan Pérez',
    clientPhone: '+1234567890',
    clientEmail: 'juan@example.com',
  ),
];
