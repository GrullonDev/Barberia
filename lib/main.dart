import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/app.dart';
import 'package:barberia/core/firebase/firebase_seed_service.dart';
import 'package:barberia/core/services/local_notification_service.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
    debugPrint('[Main] Initializing Firebase...');

    // Timeout razonable para el primer handshake.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));

    // Tareas no críticas en background — no bloquean la UI.
    _runBackgroundInitializations();

    debugPrint('[Main] Starting App...');
    runApp(const ProviderScope(child: _Bootstrap()));
  } catch (e, stack) {
    debugPrint('[Main] Initialization error: $e');
    debugPrint(stack.toString());
    // Fallback: corre la app aunque Firebase falle.
    runApp(const ProviderScope(child: MyApp()));
  }
}

/// Wrapper que ejecuta el bootstrap de auth (anónimo en web) antes de
/// renderizar la app real. Vive dentro del ProviderScope para tener acceso
/// al AuthNotifier.
class _Bootstrap extends ConsumerStatefulWidget {
  const _Bootstrap();

  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Fire-and-forget: el router ya tiene splash mientras esto ocurre.
      Future<void>.microtask(
        () => ref.read(authStateProvider.notifier).signInAnonymouslyIfWeb(),
      );
    }
  }

  @override
  Widget build(BuildContext context) => const MyApp();
}

Future<void> _runBackgroundInitializations() async {
  try {
    await FirebaseSeedService().seedIfNeeded().timeout(
      const Duration(seconds: 10),
    );
  } catch (e) {
    debugPrint('[Main] Seeding error: $e');
  }

  try {
    final LocalNotificationService notifications = LocalNotificationService();
    await notifications.init();
    await notifications.requestPermissions();
  } catch (e) {
    debugPrint('[Main] Notification error: $e');
  }
}
