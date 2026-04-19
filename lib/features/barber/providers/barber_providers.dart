import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/barber/models/barber.dart';
import 'package:barberia/features/barber/repositories/barber_repository.dart';

final Provider<BarberRepository> barberRepositoryProvider =
    Provider<BarberRepository>((Ref ref) => BarberRepository());

/// Barberos disponibles (para la UI del cliente al reservar).
final FutureProvider<List<Barber>> availableBarbersProvider =
    FutureProvider<List<Barber>>((Ref ref) async {
      return ref.watch(barberRepositoryProvider).getAvailable();
    });

/// Todos los barberos (para admin: habilitar/deshabilitar, editar perfiles).
final StreamProvider<List<Barber>> allBarbersStreamProvider =
    StreamProvider<List<Barber>>((Ref ref) {
      return ref.watch(barberRepositoryProvider).watchAll();
    });

/// Barbero por id (para mostrar nombre/foto en un AppointmentCard).
final FutureProviderFamily<Barber?, String> barberByIdProvider =
    FutureProvider.family<Barber?, String>((Ref ref, String id) async {
      if (id.isEmpty) return null;
      return ref.watch(barberRepositoryProvider).getById(id);
    });
