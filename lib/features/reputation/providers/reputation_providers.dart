import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/reputation/models/reputation.dart';
import 'package:barberia/features/reputation/repositories/reputation_repository.dart';

final Provider<ReputationRepository> reputationRepositoryProvider =
    Provider<ReputationRepository>((Ref ref) => ReputationRepository());

/// Reputación por teléfono raw; el normalizado se hace adentro.
/// Úsala con debounce desde la UI (p.ej. 400ms tras dejar de escribir).
final FutureProviderFamily<Reputation, String> reputationByPhoneProvider =
    FutureProvider.family<Reputation, String>((Ref ref, String rawPhone) async {
      return ref.watch(reputationRepositoryProvider).getByPhone(rawPhone);
    });
