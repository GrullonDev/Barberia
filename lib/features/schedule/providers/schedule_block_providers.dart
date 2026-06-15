import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/schedule/models/schedule_block.dart';
import 'package:barberia/features/schedule/repositories/schedule_block_repository.dart';

final Provider<ScheduleBlockRepository> scheduleBlockRepositoryProvider =
    Provider<ScheduleBlockRepository>((Ref ref) => ScheduleBlockRepository());

/// Stream de bloques de un barbero específico (para su agenda).
final StreamProviderFamily<List<ScheduleBlock>, String>
scheduleBlocksForBarberProvider =
    StreamProvider.family<List<ScheduleBlock>, String>((
      Ref ref,
      String barberId,
    ) {
      return ref
          .watch(scheduleBlockRepositoryProvider)
          .watchForBarber(barberId);
    });
