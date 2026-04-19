import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/config/models/barberia_config.dart';
import 'package:barberia/features/config/repositories/barberia_config_repository.dart';

final Provider<BarberiaConfigRepository> barberiaConfigRepositoryProvider =
    Provider<BarberiaConfigRepository>((Ref ref) => BarberiaConfigRepository());

/// Config global reactiva — útil para que calendar_page y settings_page
/// lean horarios/teléfono/dirección desde Firestore en lugar de hardcoded.
final StreamProvider<BarberiaConfig> barberiaConfigProvider =
    StreamProvider<BarberiaConfig>((Ref ref) {
      return ref.watch(barberiaConfigRepositoryProvider).watch();
    });
