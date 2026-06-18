import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/core/l10n/app_localizations.dart';

class AppConfigState {
  final String language; // 'es' or 'en'
  final String currencySymbol; // 'Q', '$', etc.

  AppConfigState({required this.language, required this.currencySymbol});

  factory AppConfigState.defaultConfig() {
    return AppConfigState(language: 'es', currencySymbol: 'Q');
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
