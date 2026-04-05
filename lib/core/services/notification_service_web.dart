/// No-op implementation of NotificationService for web.
/// flutter_local_notifications does not support web.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {}
  Future<void> requestPermissions() async {}
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {}
  Future<void> cancelNotification(int id) async {}
  Future<void> cancelAll() async {}
}
