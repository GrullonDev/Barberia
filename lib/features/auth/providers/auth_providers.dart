import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/repositories/auth_repository.dart';

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) => AuthRepository());

final StateNotifierProvider<AuthNotifier, User?> authStateProvider =
    StateNotifierProvider<AuthNotifier, User?>((Ref ref) {
      return AuthNotifier(ref.read(authRepositoryProvider));
    });

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier(this._repository) : super(null) {
    // Sync state with Firebase Auth on startup
    _repository.authStateChanges.listen((user) {
      state = user;
    });
  }

  final AuthRepository _repository;

  Future<bool> login(String email, String password) async {
    try {
      final user = await _repository.login(email, password);
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
    final user = await _repository.register(
      name,
      email,
      password,
      phone: phone,
    );
    state = user;
  }

  Future<void> logout() async {
    await _repository.logout();
    state = null;
  }
}
