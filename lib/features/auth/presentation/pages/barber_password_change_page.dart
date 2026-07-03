import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class BarberPasswordChangePage extends ConsumerStatefulWidget {
  const BarberPasswordChangePage({super.key});

  @override
  ConsumerState<BarberPasswordChangePage> createState() =>
      _BarberPasswordChangePageState();
}

class _BarberPasswordChangePageState
    extends ConsumerState<BarberPasswordChangePage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        throw FirebaseAuthException(code: 'no-current-user');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'mustChangePassword': false,
            'inviteStatus': 'active',
            'passwordChangedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      await ref.read(authProvider.notifier).refreshCurrentUser();

      if (!mounted) return;
      context.go('/barber/portal');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorContainer,
          content: Text(_mapAuthError(e.code)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorContainer,
          content: Text('No se pudo cambiar la contrasena: $e'),
        ),
      );
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'La contrasena temporal no coincide.';
      case 'weak-password':
        return 'La nueva contrasena es demasiado debil.';
      case 'requires-recent-login':
        return 'Vuelve a iniciar sesion con tu contrasena temporal e intenta de nuevo.';
      default:
        return 'No se pudo cambiar la contrasena. Intenta de nuevo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppRadius.borderRadiusLg,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_reset_rounded,
                        color: AppColors.secondary,
                        size: 42,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Cambia tu contrasena',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          color: AppColors.secondary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Antes de entrar al dashboard, crea una contrasena segura que solo tu conozcas.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        label: 'Contrasena temporal',
                        obscure: _obscureCurrent,
                        onToggle: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Ingresa la contrasena temporal.'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: 'Nueva contrasena',
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        validator: _validateNewPassword,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirmar contrasena',
                        obscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (value) =>
                            value != _newPasswordController.text
                            ? 'Las contrasenas no coinciden.'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _savePassword,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onSecondary,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          _isSaving ? 'Guardando...' : 'Guardar y entrar',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.onSecondary,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => ref.read(authProvider.notifier).logout(),
                        child: const Text('Cerrar sesion'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        ),
      ),
      validator: validator,
    );
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'Usa al menos 8 caracteres.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Agrega una letra mayuscula.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Agrega una letra minuscula.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Agrega un numero.';
    }
    if (password == _currentPasswordController.text) {
      return 'La nueva contrasena debe ser diferente.';
    }
    return null;
  }
}
