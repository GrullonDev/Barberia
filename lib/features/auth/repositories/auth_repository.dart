import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:barberia/features/auth/models/user.dart';

class AuthRepository {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Listens to Firebase Auth state and syncs [_currentUser].
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((fb_auth.User? fbUser) async {
      if (fbUser == null) {
        _currentUser = null;
        return null;
      }
      _currentUser = await _fetchUserProfile(fbUser.uid);
      return _currentUser;
    });
  }

  Future<User?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user == null) {
      return null;
    }
    _currentUser = await _fetchUserProfile(credential.user!.uid);
    return _currentUser;
  }

  Future<User> register(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final fb_auth.User fbUser = credential.user!;

    // Todo registro nuevo entra como 'client'.
    // Los roles admin/barber se asignan MANUALMENTE por un admin existente
    // (panel admin o consola Firebase), nunca por orden de registro ni por
    // email hardcoded. Esto evita escalada de privilegios accidental o
    // intencionada en entornos productivos.
    const UserRole role = UserRole.client;

    final User newUser = User(
      id: fbUser.uid,
      name: name.trim(),
      email: email.trim(),
      role: role,
      phone: phone,
    );

    await _db.collection('users').doc(fbUser.uid).set(newUser.toFirestore());
    _currentUser = newUser;
    return newUser;
  }

  Future<void> updatePassword(String userId, String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  Future<User?> _fetchUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return User.fromFirestore(doc);
  }
}
