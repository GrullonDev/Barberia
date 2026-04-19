/// No-op de [LocalNotificationService] para web.
/// `flutter_local_notifications` no soporta web, así que en esa plataforma
/// los métodos retornan sin efecto y el llamador no necesita diferenciar.
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

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
