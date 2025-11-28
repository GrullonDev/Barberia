import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrSigner {
  static String sign(
    final String payload, {
    final String secret = 'dev-secret',
  }) {
    final Hmac hmac = Hmac(sha256, utf8.encode(secret));
    final Digest digest = hmac.convert(utf8.encode(payload));
    return digest.toString().substring(0, 16); // corto para el QR
  }

  static String buildSignedPayload(final Map<String, Object?> data) {
    final String json = jsonEncode(data);
    final String sig = sign(json);
    return jsonEncode(<String, Object?>{'d': data, 's': sig});
  }
}
