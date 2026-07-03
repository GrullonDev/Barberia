import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { admin, barber, client }

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;
  final UserRole? role;
  final String? email;
  final String? displayName;
  final bool mustChangePassword;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
    this.role,
    this.email,
    this.displayName,
    this.mustChangePassword = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
    UserRole? role,
    String? email,
    String? displayName,
    bool? mustChangePassword,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<User?>? _authSub;

  @override
  AuthState build() {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    ref.onDispose(() => _authSub?.cancel());
    return const AuthState();
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      state = const AuthState();
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      state = AuthState(
        isAuthenticated: true,
        role: _roleFromString(doc.data()?['role'] as String?),
        email: user.email,
        displayName:
            user.displayName ??
            (doc.data()?['displayName'] ?? doc.data()?['name']) as String?,
        mustChangePassword: doc.data()?['mustChangePassword'] == true,
      );
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    required UserRole selectedRole,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      final role = _roleFromString(doc.data()?['role'] as String?);

      if (role != selectedRole) {
        await FirebaseAuth.instance.signOut();
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Role mismatch. Please select the correct role.',
        );
        return false;
      }

      state = AuthState(
        isAuthenticated: true,
        role: role,
        email: credential.user!.email,
        displayName:
            credential.user!.displayName ??
            (doc.data()?['displayName'] ?? doc.data()?['name']) as String?,
        mustChangePassword: doc.data()?['mustChangePassword'] == true,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> refreshCurrentUser() async {
    await _onAuthChanged(FirebaseAuth.instance.currentUser);
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    state = const AuthState();
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  UserRole _roleFromString(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'barber':
        return UserRole.barber;
      default:
        return UserRole.client;
    }
  }

  String _errorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account found with these credentials.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
