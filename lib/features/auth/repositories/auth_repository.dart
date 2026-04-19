import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import 'package:barberia/common/utils/phone_normalizer.dart';
import 'package:barberia/features/auth/models/user.dart';

/// Repositorio de autenticación basado en Firebase Auth.
///
/// Soporta 3 modos (ver [AuthRepository.signInAnonymously], [login],
/// [register], [sendPhoneCode]):
///
///   1. Email + password       → cliente/staff con cuenta completa.
///   2. Phone OTP (+502 …)     → cliente sin email; login con SMS.
///   3. Anonymous              → solo web; uid temporal para que el cliente
///                               pueda navegar sin fricción y, si luego se
///                               registra, hacer `linkWithCredential`.
///
/// Todo usuario Firebase Auth tiene un doc espejo en `users/{uid}` con su
/// rol y datos básicos. Si al loguear se detecta un uid sin doc espejo
/// (caso típico: sesión anónima, o registro que dejó doc a medias en un
/// crash previo), se CREA uno como 'client' sobre la marcha para evitar
/// el loop infinito de redirección hacia /login.
class AuthRepository {
  AuthRepository({fb_auth.FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? fb_auth.FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final fb_auth.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Verificador de teléfono actual (entre `sendPhoneCode` y `verifyPhoneCode`).
  /// Solo válido en móvil; en web Firebase usa un flujo distinto con reCAPTCHA.
  String? _pendingPhoneVerificationId;

  /// Stream de cambios de estado. Si el fbUser existe pero no tiene doc
  /// en `users/`, crea uno como client por defecto (idempotente).
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((fb_auth.User? fbUser) async {
      if (fbUser == null) {
        _currentUser = null;
        return null;
      }
      _currentUser = await _ensureUserProfile(fbUser);
      return _currentUser;
    });
  }

  // ---------------------------------------------------------------------------
  // Email + password
  // ---------------------------------------------------------------------------

  Future<User?> login(String email, String password) async {
    final fb_auth.UserCredential credential =
        await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user == null) return null;
    _currentUser = await _ensureUserProfile(credential.user!);
    return _currentUser;
  }

  Future<User> register(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    final fb_auth.UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final fb_auth.User fbUser = credential.user!;

    // Todo registro nuevo entra como 'client' (ver Phase 0). Admin/barber
    // se promueven manualmente desde el panel admin.
    final User newUser = User(
      id: fbUser.uid,
      name: name.trim(),
      email: email.trim(),
      role: UserRole.client,
      phone: phone,
      phoneNormalized: normalizePhone(phone),
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(fbUser.uid).set(newUser.toFirestore());
    _currentUser = newUser;
    return newUser;
  }

  /// Envía correo de recuperación de contraseña.
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updatePassword(String userId, String newPassword) async {
    final fb_auth.User? user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  // ---------------------------------------------------------------------------
  // Phone OTP
  //
  // Flujo móvil (Android/iOS):
  //   1. Cliente llama `sendPhoneCode(number)` → Firebase envía SMS.
  //   2. `verifyPhoneCode(code)` → completa el sign-in.
  //
  // En web se necesita reCAPTCHA invisible (`RecaptchaVerifier`). Este
  // flujo mínimo es para mobile; web se puede añadir cuando se active.
  // ---------------------------------------------------------------------------

  /// Dispara el envío de OTP al teléfono `e164` (ej. '+50212345678').
  /// Devuelve un `Future<String>` con el `verificationId` (también guardado
  /// internamente para que [verifyPhoneCode] funcione sin pasarlo).
  ///
  /// En auto-retrieval (Android), el callback `verificationCompleted` puede
  /// loguear al usuario sin que teclee el código. Aquí lo ignoramos por
  /// simplicidad; lo propagamos como error para que la UI pida el código.
  Future<String> sendPhoneCode(String e164) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Phone OTP en web requiere RecaptchaVerifier; no habilitado aún.',
      );
    }
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {
        // Android auto-retrieval: ignorado para forzar flujo manual simple.
      },
      verificationFailed: (fb_auth.FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        _pendingPhoneVerificationId = verificationId;
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _pendingPhoneVerificationId = verificationId;
      },
    );
    return completer.future;
  }

  /// Completa el sign-in con el código SMS de 6 dígitos.
  Future<User?> verifyPhoneCode(String smsCode) async {
    final String? vid = _pendingPhoneVerificationId;
    if (vid == null) {
      throw StateError('Llama antes a sendPhoneCode.');
    }
    final fb_auth.PhoneAuthCredential credential =
        fb_auth.PhoneAuthProvider.credential(
      verificationId: vid,
      smsCode: smsCode,
    );
    final fb_auth.UserCredential userCred =
        await _auth.signInWithCredential(credential);
    if (userCred.user == null) return null;
    _currentUser = await _ensureUserProfile(userCred.user!);
    _pendingPhoneVerificationId = null;
    return _currentUser;
  }

  // ---------------------------------------------------------------------------
  // Anonymous (web-only boot path)
  // ---------------------------------------------------------------------------

  /// Inicia sesión anónima. Idempotente: si ya hay un fbUser (anónimo o no),
  /// no hace nada.
  ///
  /// La regla de seguridad de Firestore trata a los anónimos como NO staff
  /// y NO owner de bookings, así que solo podrán leer colecciones públicas
  /// (services/barbers/config) y llamar a reserveSlot CF para reservar.
  Future<User?> signInAnonymously() async {
    if (_auth.currentUser != null) {
      _currentUser = await _ensureUserProfile(_auth.currentUser!);
      return _currentUser;
    }
    final fb_auth.UserCredential cred = await _auth.signInAnonymously();
    if (cred.user == null) return null;
    _currentUser = await _ensureUserProfile(cred.user!);
    return _currentUser;
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _pendingPhoneVerificationId = null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Lee `users/{uid}`; si no existe, lo crea como client por defecto.
  /// Soluciona el loop de redirección cuando hay fbUser pero falta doc espejo
  /// (por ejemplo tras signInAnonymously o por crashes a mitad de registro).
  Future<User> _ensureUserProfile(fb_auth.User fbUser) async {
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection('users').doc(fbUser.uid);
    final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();

    if (snap.exists) {
      return User.fromFirestore(snap);
    }

    // Crea doc espejo como client. Para anónimos, marcamos isAnonymous=true
    // para que el router sepa no bloquearlos pero tampoco mostrarles /admin.
    final String phone = fbUser.phoneNumber ?? '';
    final User fallback = User(
      id: fbUser.uid,
      name: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
      role: UserRole.client,
      phone: phone.isEmpty ? null : phone,
      phoneNormalized: normalizePhone(phone),
      photoUrl: fbUser.photoURL,
      isAnonymous: fbUser.isAnonymous,
      createdAt: DateTime.now(),
    );
    await ref.set(fallback.toFirestore());
    return fallback;
  }
}
