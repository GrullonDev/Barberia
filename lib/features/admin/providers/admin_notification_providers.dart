import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/features/admin/models/admin_notification.dart';
import 'package:barberia/features/admin/repositories/admin_notification_repository.dart';

final Provider<AdminNotificationRepository> adminNotificationRepositoryProvider =
    Provider<AdminNotificationRepository>(
      (Ref ref) => AdminNotificationRepository(),
    );

final StreamProvider<List<AdminNotification>> adminNotificationsProvider =
    StreamProvider<List<AdminNotification>>((Ref ref) {
      return ref.watch(adminNotificationRepositoryProvider).watchRecent();
    });
