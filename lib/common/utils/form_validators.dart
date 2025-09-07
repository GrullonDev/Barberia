class FormValidators {
  static String? validateEmail(final String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  static String? validatePhone(final String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }
    final RegExp phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Ingresa un teléfono válido';
    }
    return null;
  }

  static String? validateName(final String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  static String? validateRequired(final String? value, final String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }
}
