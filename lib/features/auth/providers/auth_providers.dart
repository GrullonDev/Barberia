import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/repositories/auth_repository.dart';

/// Estado de bootstrap de autenticación:
/// - [loading]  → inicializando, el router debe mostrar splash.
/// - [ready]    → listo; el [authStateProvider] tiene el usuario actual o null.
enum AuthBootstrap { loading, ready }

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) => AuthRepository());

/// Indica si Firebase Auth ya terminó de rehidratar la sesión persistida.
/// Mientras esté [AuthBootstrap.loading] evitamos redirecciones prematuras
/// a `/login`.
final StateProvider<AuthBootstrap> authBootstrapProvider =
    StateProvider<AuthBootstrap>((Ref ref) => AuthBootstrap.loading);

final StateNotifierProvider<AuthNotifier, User?> authStateProvider =
    StateNotifierProvider<AuthNotifier, User?>((Ref ref) {
      return AuthNotifier(ref.read(authRepositoryProvider), ref);
    });

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier(this._repository, this._ref) : super(null) {
    _repository.authStateChanges.listen((User? user) {
      state = user;
      // Primer evento → bootstrap terminado.
      _ref.read(authBootstrapProvider.notifier).state = AuthBootstrap.ready;
    });
  }

  final AuthRepository _repository;
  final Ref _ref;

  Future<bool> login(String email, String password) async {
    try {
      final User? user = await _repository.login(email, password);
      if (user != null) {
        state = user;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    final User user = await _repository.register(
      name,
      email,
      password,
      phone: phone,
    );
    state = user;
  }

  Future<void> sendPasswordReset(String email) =>
      _repository.sendPasswordReset(email);

  Future<String> sendPhoneCode(String e164) => _repository.sendPhoneCode(e164);

  Future<bool> verifyPhoneCode(String smsCode) async {
    try {
      final User? user = await _repository.verifyPhoneCode(smsCode);
      if (user != null) {
        state = user;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Bootstrap para web: si no hay sesión, crea una anónima. Idempotente.
  /// Seguro llamar desde main.dart también en móvil (saldrá no-op si ya hay
  /// sesión), pero el contrato es que solo se invoca en web (ver main.dart).
  Future<void> signInAnonymouslyIfWeb() async {
    if (!kIsWeb) {
      return;
    }
    if (_repository.currentUser != null) {
      return;
    }
    try {
      final User? user = await _repository.signInAnonymously();
      if (user != null) {
        state = user;
      }
    } catch (e) {
      // Si falla, el cliente puede seguir navegando pero no reservar.
      debugPrint('[Auth] signInAnonymously failed: $e');
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = null;
  }
}
