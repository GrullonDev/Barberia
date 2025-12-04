import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  static Future<void> sendWhatsApp({
    required String phone,
    required String message,
  }) async {
    // Eliminar caracteres no numéricos del teléfono
    final String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Crear URL de WhatsApp
    // Nota: Se asume que el teléfono incluye código de país o se maneja localmente.
    // Para mayor robustez, se podría pedir el código de país por separado.
    final Uri url = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback o manejo de error silencioso
      print('No se pudo abrir WhatsApp para $cleanPhone');
    }
  }

  static Future<void> sendEmail({
    required String email,
    required String subject,
    required String body,
  }) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      print('No se pudo abrir cliente de correo para $email');
    }
  }

  static String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
