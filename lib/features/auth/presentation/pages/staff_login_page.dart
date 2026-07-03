import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class StaffLoginPage extends ConsumerStatefulWidget {
  const StaffLoginPage({super.key});

  @override
  ConsumerState<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends ConsumerState<StaffLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.barber;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
          selectedRole: _selectedRole,
        );

    if (mounted) {
      if (success) {
        // Show a beautiful luxury "Access Granted" overlay/dialog
        _showSuccessDialog();
      } else {
        // Clear password on failure
        _passwordController.clear();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(color: AppColors.secondary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 2),
                ),
                child: const Icon(
                  Icons.vpn_key_outlined,
                  color: AppColors.secondary,
                  size: 32,
                ),
              ).animate().scale(
                delay: 100.ms,
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'ACCESS GRANTED',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _selectedRole == UserRole.admin
                    ? 'Welcome back, Administrator'
                    : 'Welcome back, Master Barber',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss Dialog
                  if (_selectedRole == UserRole.barber) {
                    context.go('/barber/portal');
                  } else {
                    context.go('/admin/portal');
                  }
                },
                child: const Text('ENTER PORTAL'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Watch for error message and display using a custom Snack Bar
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorContainer,
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.onErrorContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    next.errorMessage!,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: AppColors.onErrorContainer,
              onPressed: _clearAuthErrorIfMounted,
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ─── Ambient Background Glows ──────────────────────────────────────────
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.02),
              ),
            ),
          ),

          // ─── Main Content Scrollable Area ──────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),

                      // Brand Header
                      Column(
                            children: [
                              Text(
                                "The Gentleman's Lounge",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ESTABLISHED 1924',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 4,
                                  color: AppColors.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl * 1.5),
                              Text(
                                'STAFF PORTAL ACCESS',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.1, end: 0, duration: 600.ms),

                      const SizedBox(height: AppSpacing.xl),

                      // Form Container Card
                      Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: AppRadius.borderRadiusLg,
                              border: Border.all(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Role Selection Sliding Toggle
                                  _buildRoleToggle(),
                                  const SizedBox(height: AppSpacing.xl),

                                  // Email Input
                                  _buildLabel('EMAIL ADDRESS'),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      hintText: 'staff@thegentlemanslounge.com',
                                      prefixIcon: Icon(
                                        Icons.mail_outline_rounded,
                                        size: 20,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      final emailRegex = RegExp(
                                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                      );
                                      if (!emailRegex.hasMatch(value)) {
                                        return 'Please enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // Password Input
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildLabel('PASSWORD'),
                                      GestureDetector(
                                        onTap: () {
                                          // Simulated Reset
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please contact the Lounge System Administrator to reset your password.',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Forgot?',
                                          style: AppTextStyles.labelSm.copyWith(
                                            color: AppColors.onSurface
                                                .withValues(alpha: 0.5),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 20,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.xl),

                                  // Secure Entrance Button
                                  ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.secondary,
                                          foregroundColor:
                                              AppColors.onSecondary,
                                          minimumSize: const Size(
                                            double.infinity,
                                            54,
                                          ),
                                          shape: const RoundedRectangleBorder(
                                            borderRadius:
                                                AppRadius.borderRadiusMd,
                                          ),
                                          elevation: 4,
                                        ),
                                        onPressed: authState.isLoading
                                            ? null
                                            : _handleLogin,
                                        child: authState.isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(AppColors.onSecondary),
                                                ),
                                              )
                                            : Text(
                                                'SECURE ENTRANCE',
                                                style:
                                                    GoogleFonts.hankenGrotesk(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 2,
                                                    ),
                                              ),
                                      )
                                      .animate(
                                        target: authState.isLoading ? 0 : 1,
                                      )
                                      .shimmer(
                                        duration: 1800.ms,
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                        delay: 3.seconds,
                                      ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            delay: 200.ms,
                            duration: 600.ms,
                          ),

                      const SizedBox(height: AppSpacing.xl),

                      // Exit Option
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: Text(
                            'CLIENT PORTAL',
                            style: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppColors.secondary,
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 2;
          return Stack(
            children: [
              // Sliding active background indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                alignment: _selectedRole == UserRole.barber
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: width - 4,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                ),
              ),

              // Toggle labels
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRole = UserRole.barber;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: _selectedRole == UserRole.barber
                                ? AppColors.onSecondary
                                : AppColors.onSurfaceVariant,
                          ),
                          child: const Text('BARBER'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRole = UserRole.admin;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: _selectedRole == UserRole.admin
                                ? AppColors.onSecondary
                                : AppColors.onSurfaceVariant,
                          ),
                          child: const Text('ADMIN'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

