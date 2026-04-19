// Conditional re-export: usa el plugin real en móvil, stub no-op en web.
export 'local_notification_service_mobile.dart'
    if (dart.library.html) 'local_notification_service_web.dart';
