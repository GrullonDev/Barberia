// Conditional re-export: uses real plugin on mobile, no-op stub on web.
export 'notification_service_mobile.dart'
    if (dart.library.html) 'notification_service_web.dart';
