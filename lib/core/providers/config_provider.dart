import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/core/l10n/app_localizations.dart';

class AppConfigState {
  final String language; // 'es' or 'en'
  final String currencySymbol; // 'Q', '$', etc.
  final int timezoneOffsetHours; // ej. -6 para Guatemala. Debe coincidir
  // con `config/barberia.timezoneOffsetHours` leído por las Cloud Functions
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
  return FirebaseFirestore.instance
      .collection('config')
      .doc('barberia')
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
