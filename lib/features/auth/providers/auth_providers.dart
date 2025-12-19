import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/repositories/auth_repository.dart';

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) {
      return AuthRepository();
    });

final StateNotifierProvider<AuthNotifier, User?> authStateProvider =
    StateNotifierProvider<AuthNotifier, User?>((Ref ref) {
      return AuthNotifier(ref.read(authRepositoryProvider));
    });

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier(this._repository) : super(null);

  final AuthRepository _repository;

  Future<bool> login(String email, String password) async {
    final user = await _repository.login(email, password);
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  Future<void> register(String name, String email, String password) async {
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password,
      role: UserRole.client, // Default to client
    );
    await _repository.register(user);
    state = user;
  }

  Future<void> logout() async {
    await _repository.logout();
    state = null;
  }
}
