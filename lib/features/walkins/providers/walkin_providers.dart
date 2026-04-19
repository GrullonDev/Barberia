import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/walkins/models/walkin.dart';
import 'package:barberia/features/walkins/repositories/walkin_repository.dart';

final Provider<WalkInRepository> walkInRepositoryProvider =
    Provider<WalkInRepository>((Ref ref) => WalkInRepository());

/// Cola activa de walk-ins (waiting + inService) — para la pantalla del barbero.
final StreamProvider<List<WalkIn>> activeWalkInsProvider =
    StreamProvider<List<WalkIn>>((Ref ref) {
      return ref.watch(walkInRepositoryProvider).watchActive();
    });
