import 'package:flutter/services.dart';

/// Formatea teléfonos de Guatemala (8 dígitos): #### ####.
class GtPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final String limited = digits.length > 8 ? digits.substring(0, 8) : digits;
    String formatted = limited;
    if (limited.length > 4) {
      formatted = '${limited.substring(0, 4)} ${limited.substring(4)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
