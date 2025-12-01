import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/common/database_helper.dart';

class AuthState {
  final User? currentUser;
  final bool isSignedIn;

  AuthState({this.currentUser, this.isSignedIn = false});

  AuthState copyWith({
    User? currentUser,
    bool? isSignedIn,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isSignedIn: isSignedIn ?? this.isSignedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username != null) {
      final user = await DatabaseHelper.instance.readUserByUsername(username);
      if (user != null) {
        state = AuthState(currentUser: user, isSignedIn: true);
      }
    }
  }

  Future<bool> login(String username, String password) async {
    final user = await DatabaseHelper.instance.authenticateUser(username, password);
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', user.username);
      state = AuthState(currentUser: user, isSignedIn: true);
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String password) async {
    final existingUser = await DatabaseHelper.instance.readUserByUsername(username);
    if (existingUser != null) {
      return false; // User already exists
    }
    final newUser = User(username: username, password: password, role: UserRole.client);
    await DatabaseHelper.instance.createUser(newUser);
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    state = AuthState(currentUser: null, isSignedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
