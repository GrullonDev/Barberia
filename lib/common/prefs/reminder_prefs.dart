import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste la preferencia de recibir recordatorios (bool).
class ReminderPrefsNotifier extends StateNotifier<bool> {
  ReminderPrefsNotifier() : super(false) {
    // Carga diferida para no bloquear construcción.
    unawaited(_load());
  }

  static const String _key = 'reminders_opt_in';

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? false;
    } catch (_) {/* ignore */}
  }

  Future<void> set(bool value) async {
    state = value;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {/* ignore */}
  }
}

final StateNotifierProvider<ReminderPrefsNotifier, bool> reminderOptInProvider =
    StateNotifierProvider<ReminderPrefsNotifier, bool>(
  (Ref ref) => ReminderPrefsNotifier(),
);
