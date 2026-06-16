import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/common/utils/phone_normalizer.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';

/// Flujo de login por SMS en 2 pasos:
///   1. Usuario ingresa su número (formato libre, normalizamos a +502…).
///   2. Ingresa el código de 6 dígitos que llega por SMS.
///
/// Solo mobile por ahora: en web Firebase requiere reCAPTCHA invisible,
/// y la UX en web la cubrimos con el flujo anónimo + reserveSlot CF.
class PhoneLoginPage extends ConsumerStatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  ConsumerState<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends ConsumerState<PhoneLoginPage> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _sendCode() async {
    final String e164 = normalizePhone(_phoneCtrl.text);
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).sendPhoneCode(e164);
      if (!mounted) {
        return;
      }
      setState(() => _codeSent = true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'No pudimos enviar el SMS: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.trim().length < 4) {
      setState(() => _error = 'Ingresa el código recibido.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bool ok = await ref
          .read(authStateProvider.notifier)
          .verifyPhoneCode(_codeCtrl.text.trim());
      if (!mounted) {
        return;
      }
      if (!ok) {
        setState(() => _error = 'Código incorrecto.');
      }
      // Si OK, el router redirige automáticamente al home.
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Fallo verificando el código.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar con teléfono')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!_codeSent) ...<Widget>[
                  const Text(
                    'Te enviaremos un SMS con un código de 6 dígitos.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      hintText: '+502 1234 5678',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _sendCode,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar código'),
                  ),
                ] else ...<Widget>[
                  Text('Código enviado a ${_phoneCtrl.text.trim()}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Código',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _verify,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verificar'),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                            _codeSent = false;
                            _codeCtrl.clear();
                            _error = null;
                          }),
                    child: const Text('Cambiar número'),
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
