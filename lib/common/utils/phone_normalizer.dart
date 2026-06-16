/// Normalizador de teléfonos para uso como clave canónica.
///
/// Todas las variantes de un mismo número tienen que producir la MISMA clave
/// para que la reputación funcione correctamente entre:
///   - cliente invitado que reserva desde web con "+502 4290-9548"
///   - el mismo cliente registrado en la app móvil con "42909548"
///   - ese mismo cliente capturado por el barbero como walk-in con "(502) 4290 9548"
///
/// Convenciones:
///   - Quita todo lo que no sea dígito ni '+'.
///   - Conserva un solo '+' inicial si venía.
///   - Si el número empieza por '+' con código de país, se respeta.
///   - Si viene sin '+' y tiene 8 dígitos (teléfono local Guatemala), se le
///     antepone '+502' por convención. Ajusta [_defaultCountryCode] para otro país.
///   - Si viene sin '+' y tiene 10+ dígitos, se asume que incluye código
///     de país y se le antepone '+' sin tocar.
///
/// Ejemplos:
///   '+502 4290-9548'   -> '+50242909548'
///   '4290-9548'        -> '+50242909548'
///   '42909548'         -> '+50242909548'
///   '(502) 4290 9548'  -> '+50242909548'
///   '50242909548'      -> '+50242909548'
///   ''                 -> ''  (entrada vacía → salida vacía)
const String _defaultCountryCode = '+502';
const int _localDigitsGt = 8;

String normalizePhone(String? raw) {
  if (raw == null) {
    return '';
  }
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final bool startsWithPlus = trimmed.startsWith('+');
  final String digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) {
    return '';
  }

  if (startsWithPlus) {
    return '+$digitsOnly';
  }

  // Teléfono local Guatemala típico (8 dígitos)
  if (digitsOnly.length == _localDigitsGt) {
    return '$_defaultCountryCode$digitsOnly';
  }

  // Incluye código de país pero sin '+'
  return '+$digitsOnly';
}

/// `true` si el input normalizado es un teléfono mínimamente válido.
/// Útil para validación pre-lookup en reputación.
bool isValidNormalizedPhone(String? raw) {
  final String n = normalizePhone(raw);
  // Mínimo +X y 8 dígitos, máximo +X y 15 (E.164)
  if (!n.startsWith('+')) {
    return false;
  }
  final int digits = n.length - 1;
  return digits >= 8 && digits <= 15;
}
