import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/core/l10n/app_localizations.dart';
import 'package:barberia/features/auth/presentation/providers/auth_provider.dart';

// Shop de fallback para sesiones sin staff autenticado (la app pública de
// reservas). Cada deploy de cliente se compila con su propio shopId:
//   flutter build web --dart-define=SHOP_ID=nombre_del_shop
// Si no se pasa nada, cae en "barberia" (el tenant actual/único hoy).
const String _kFallbackShopId = String.fromEnvironment(
  'SHOP_ID',
  defaultValue: 'barberia',
);

/// Shop activo para esta sesión.
///
/// - Staff logueado (admin/barber): su propio `users/{uid}.shopId` — es la
///   fuente de verdad real, nunca se confía en un valor compilado para
///   staff, porque un mismo build podría en teoría autenticar contra
///   cualquier cuenta.
/// - Sin sesión de staff (cliente público de la app de reservas): el
///   shopId fijado en tiempo de compilación para este deploy.
final currentShopIdProvider = Provider<String>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.isAuthenticated && auth.shopId != null) {
    return auth.shopId!;
  }
  return _kFallbackShopId;
});

class AppConfigState {
  final String language; // 'es' or 'en'
  final String currencySymbol; // 'Q', '$', etc.
  final int timezoneOffsetHours; // ej. -6 para Guatemala. Debe coincidir
  // con `shops/{shopId}.timezoneOffsetHours` leído por las Cloud Functions
  // (ver backend/functions/main.py:_load_config) para que la disponibilidad
  // mostrada en la app y la validada al reservar usen la misma hora local.
  final double monthlyTarget; // meta de ingresos mensuales del admin dashboard

  AppConfigState({
    required this.language,
    required this.currencySymbol,
    required this.timezoneOffsetHours,
    this.monthlyTarget = 0,
  });

  factory AppConfigState.defaultConfig() {
    return AppConfigState(
      language: 'es',
      currencySymbol: 'Q',
      timezoneOffsetHours: -6,
      monthlyTarget: 0,
    );
  }
}

final appConfigStreamProvider = StreamProvider<AppConfigState>((ref) {
  final shopId = ref.watch(currentShopIdProvider);
  return FirebaseFirestore.instance
      .collection('shops')
      .doc(shopId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) {
          return AppConfigState.defaultConfig();
        }
        final data = doc.data() ?? {};
        return AppConfigState(
          language: data['language'] ?? 'es',
          currencySymbol: data['currencySymbol'] ?? 'Q',
          timezoneOffsetHours:
              (data['timezoneOffsetHours'] as num?)?.toInt() ?? -6,
          monthlyTarget: (data['monthlyTarget'] as num?)?.toDouble() ?? 0,
        );
      });
});

final appConfigProvider = Provider<AppConfigState>((ref) {
  return ref
      .watch(appConfigStreamProvider)
      .maybeWhen(
        data: (config) => config,
        orElse: () => AppConfigState.defaultConfig(),
      );
});

final l10nProvider = Provider<AppLocalizations>((ref) {
  final config = ref.watch(appConfigProvider);
  return AppLocalizations(config.language);
});
