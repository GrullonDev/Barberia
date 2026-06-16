import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';

const Color _ink = Color(0xFF101312);
const Color _panel = Color(0xFF1D201F);
const Color _field = Color(0xFF292C2A);
const Color _line = Color(0xFF3A3D39);
const Color _gold = Color(0xFFE8C84E);
const Color _muted = Color(0xFFB8B8B2);
const String _patternAsset = 'assets/images/barber_bg_pattern.png';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _staffMode = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final bool success = await ref
        .read(authStateProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
    if (success) {
      context.goNamed(RouteNames.home);
    } else {
      setState(() => _error = 'Credenciales invalidas');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _ink,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _gold,
          selectionColor: Color(0x55E8C84E),
          selectionHandleColor: _gold,
        ),
      ),
      child: Scaffold(
        backgroundColor: _ink,
        body: isDesktop
            ? _DesktopLogin(shell: _formShell())
            : _MobileLogin(shell: _formShell()),
      ),
    );
  }

  Widget _formShell() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _SegmentedAccess(
            staffMode: _staffMode,
            onChanged: (bool value) => setState(() => _staffMode = value),
          ),
          const SizedBox(height: 30),
          _LuxuryField(
            controller: _emailCtrl,
            label: _staffMode ? 'EMAIL STAFF' : 'EMAIL O TELEFONO',
            hint: _staffMode ? 'staff@gentleman.com' : 'gentleman@example.com',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          _LuxuryField(
            controller: _passCtrl,
            label: 'PASSWORD',
            hint: '********',
            obscureText: _obscureText,
            icon: _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onIconPressed: () => setState(() => _obscureText = !_obscureText),
            trailingLabel: 'Forgot?',
            onTrailingTap: () => context.pushNamed(RouteNames.passwordReset),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              return null;
            },
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 18),
            _ErrorNotice(message: _error!),
          ],
          const SizedBox(height: 28),
          _GoldSubmitButton(
            loading: _isLoading,
            label: _staffMode ? 'STAFF ACCESS' : 'SIGN IN',
            onPressed: _isLoading ? null : _submit,
          ),
          const SizedBox(height: 30),
          const _DividerLabel(label: 'OR CONTINUE WITH'),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _SecondaryAccessButton(
                  icon: Icons.phone_iphone,
                  label: 'Phone',
                  onTap: () => context.pushNamed(RouteNames.phoneLogin),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SecondaryAccessButton(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Join',
                  onTap: () => context.pushNamed(RouteNames.register),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const Text(
                  'First visit? ',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                InkWell(
                  onTap: () => context.pushNamed(RouteNames.register),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Request Membership',
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLogin extends StatelessWidget {
  const _DesktopLogin({required this.shell});

  final Widget shell;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(_patternAsset, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.38),
              radius: 1.05,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.36),
                Colors.black.withValues(alpha: 0.82),
                Colors.black,
              ],
            ),
          ),
        ),
        Column(
          children: <Widget>[
            const _DesktopHeader(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: _LoginCard(
                    title: 'Welcome Back',
                    subtitle: 'Enter your credentials to access the lounge',
                    child: shell,
                  ),
                ),
              ),
            ),
            const _DesktopFooter(),
          ],
        ),
      ],
    );
  }
}

class _MobileLogin extends StatelessWidget {
  const _MobileLogin({required this.shell});

  final Widget shell;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_patternAsset),
          fit: BoxFit.cover,
          opacity: 0.06,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            28,
            34,
            28,
            MediaQuery.paddingOf(context).bottom + 34,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  68,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _MobileBrand(),
                const SizedBox(height: 70),
                shell,
                const SizedBox(height: 54),
                TextButton(
                  onPressed: () => context.goNamed(RouteNames.home),
                  child: const Text(
                    'Continue as guest',
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.54),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Row(
              children: <Widget>[
                Text(
                  "The Gentleman's Lounge",
                  style: GoogleFonts.playfairDisplay(
                    color: _gold,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                _HeaderLink(
                  label: 'SERVICES',
                  onTap: () => context.goNamed(RouteNames.services),
                ),
                _HeaderLink(
                  label: 'BARBERS',
                  onTap: () => context.goNamed(RouteNames.home),
                ),
                _HeaderLink(
                  label: 'GIFT CARDS',
                  onTap: () => context.goNamed(RouteNames.home),
                ),
                const SizedBox(width: 60),
                IconButton(
                  tooltip: 'Ayuda',
                  onPressed: () {},
                  icon: const Icon(Icons.help_outline, color: _gold, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(54, 50, 54, 48),
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.94),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.46),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFD6D6D0), fontSize: 17),
          ),
          const SizedBox(height: 44),
          child,
        ],
      ),
    );
  }
}

class _MobileBrand extends StatelessWidget {
  const _MobileBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          "The Gentleman's Lounge",
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: _gold,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'ESTABLISHED 1924',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            letterSpacing: 5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SegmentedAccess extends StatelessWidget {
  const _SegmentedAccess({required this.staffMode, required this.onChanged});

  final bool staffMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _field,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SegmentOption(
              label: 'CLIENT',
              selected: !staffMode,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _SegmentOption(
              label: 'STAFF',
              selected: staffMode,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        color: selected ? _gold : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _LuxuryField extends StatelessWidget {
  const _LuxuryField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.onIconPressed,
    this.trailingLabel,
    this.onTrailingTap,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onIconPressed;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            if (trailingLabel != null)
              InkWell(
                onTap: onTrailingTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    trailingLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.34),
              fontSize: 17,
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            suffixIcon: IconButton(
              onPressed: onIconPressed,
              icon: Icon(icon, color: Colors.white.withValues(alpha: 0.48)),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _line),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _gold, width: 1.5),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            errorStyle: const TextStyle(color: Color(0xFFFFA4A4)),
          ),
        ),
      ],
    );
  }
}

class _GoldSubmitButton extends StatelessWidget {
  const _GoldSubmitButton({
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final bool loading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _gold,
        disabledBackgroundColor: _gold.withValues(alpha: 0.5),
        foregroundColor: Colors.black,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.black,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
    );
  }
}

class _SecondaryAccessButton extends StatelessWidget {
  const _SecondaryAccessButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(vertical: 18),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(height: 1, color: _line.withValues(alpha: 0.6)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: _line.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF451A1A),
        border: Border.all(color: const Color(0xFF7F1D1D)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: Color(0xFFFFA4A4), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFFD1D1),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopFooter extends StatelessWidget {
  const _DesktopFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(44, 18, 44, 26),
      child: Row(
        children: <Widget>[
          const Text(
            "© 2024 The Gentleman's Lounge. All Rights Reserved.",
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.pushNamed(RouteNames.privacy),
            child: const Text(
              'PRIVACY POLICY',
              style: TextStyle(color: _muted),
            ),
          ),
          const SizedBox(width: 20),
          const Text('TERMS OF SERVICE', style: TextStyle(color: _muted)),
          const SizedBox(width: 20),
          const Text('CONTACT', style: TextStyle(color: _muted)),
        ],
      ),
    );
  }
}
