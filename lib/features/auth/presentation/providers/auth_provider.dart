import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { admin, barber, client }

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;
  final UserRole? role;
  final String? email;
  final String? displayName;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
    this.role,
    this.email,
    this.displayName,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
    UserRole? role,
    String? email,
    String? displayName,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          errorMessage, // We set directly so we can pass null to clear error
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<bool> login({
    required String email,
    required String password,
    required UserRole selectedRole,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Simulate network latency for premium feel
    await Future.delayed(const Duration(milliseconds: 1500));

    final cleanEmail = email.trim().toLowerCase();

    // Mock validation matching the requested roles
    if (selectedRole == UserRole.admin) {
      if (cleanEmail == 'admin@lounge.com' && password == 'admin123') {
        state = AuthState(
          isAuthenticated: true,
          role: UserRole.admin,
          email: cleanEmail,
          displayName: 'Lounge Admin',
        );
        return true;
      }
    } else if (selectedRole == UserRole.barber) {
      if (cleanEmail == 'barber@lounge.com' && password == 'barber123') {
        state = AuthState(
          isAuthenticated: true,
          role: UserRole.barber,
          email: cleanEmail,
          displayName: 'Master Barber',
        );
        return true;
      }
    }

    // Fallback failure case
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Invalid credentials or role mismatch. Please try again.',
    );
    return false;
  }

  void logout() {
    state = const AuthState();
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
