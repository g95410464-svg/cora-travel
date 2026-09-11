import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';

class ChatException implements Exception {
  final String message;
  const ChatException(this.message);
}

class ChatApi {
  final http.Client _client = http.Client();

  Future<String> send(String message, String userId,
      {Map<String, Object> context = const {}}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'userId': userId,
              'context': context,
            }),
          )
          .timeout(const Duration(seconds: 65));
      if (response.statusCode != 200) {
        throw ChatException(switch (response.statusCode) {
          400 => 'Revisa tu mensaje e intenta de nuevo.',
          429 => 'Dame un minuto antes de continuar.',
          503 => 'Falta configurar la IA en el backend.',
          504 => 'La respuesta tardó demasiado. Intenta de nuevo.',
          _ => 'No pude responder ahora. Intenta de nuevo.',
        });
      }
      final data = jsonDecode(response.body);
      if (data is! Map || data['reply'] is! String) {
        throw const ChatException('La respuesta del servidor no es válida.');
      }
      return data['reply'] as String;
    } on ChatException {
      rethrow;
    } on TimeoutException {
      throw const ChatException(
        'El servidor tardó demasiado. Intenta de nuevo.',
      );
    } catch (_) {
      throw const ChatException(
        'No pude conectar con CORA. Revisa tu conexión y el backend.',
      );
    }
  }

  void dispose() => _client.close();
}
