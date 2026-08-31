import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../features/affirmations/data/models/models.dart';

class ApiKeyValidationResult {
  final bool isValid;
  final String message;

  const ApiKeyValidationResult({required this.isValid, required this.message});
}

class ApiValidationService {
  static Future<ApiKeyValidationResult> validateKey(ProviderAI provider, String rawApiKey) async {
    // Recorta espacios/saltos de línea invisibles que suelen colarse al pegar
    // la key desde el portapapeles del celular — antes se usaba tal cual y
    // eso hacía fallar la autenticación aunque la key fuera correcta.
    final apiKey = rawApiKey.trim();
    if (apiKey.isEmpty) {
      return const ApiKeyValidationResult(isValid: false, message: 'Ingresa una API Key.');
    }

    try {
      late final http.Response res;
      switch (provider) {
        case ProviderAI.openai:
          res = await http
              .get(
                Uri.parse('https://api.openai.com/v1/models'),
                headers: {'Authorization': 'Bearer $apiKey'},
              )
              .timeout(const Duration(seconds: 15));

        case ProviderAI.gemini:
          res = await http
              .get(Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'))
              .timeout(const Duration(seconds: 15));

        case ProviderAI.anthropic:
          res = await http
              .post(
                Uri.parse('https://api.anthropic.com/v1/messages'),
                headers: {
                  'x-api-key': apiKey,
                  'anthropic-version': '2023-06-01',
                  'content-type': 'application/json',
                },
                body: jsonEncode({
                  'model': 'claude-3-haiku-20240307',
                  'max_tokens': 1,
                  'messages': [{'role': 'user', 'content': 'hi'}],
                }),
              )
              .timeout(const Duration(seconds: 15));
      }

      if (res.statusCode == 200) {
        return const ApiKeyValidationResult(isValid: true, message: 'API Key válida y lista para usar.');
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        return const ApiKeyValidationResult(isValid: false, message: 'API Key inválida o sin permisos.');
      }
      if (res.statusCode == 429) {
        return const ApiKeyValidationResult(
          isValid: false,
          message: 'La key es válida, pero se alcanzó el límite/cuota de la cuenta (HTTP 429).',
        );
      }
      return ApiKeyValidationResult(
        isValid: false,
        message: 'El proveedor respondió con error HTTP ${res.statusCode}.',
      );
    } on TimeoutException {
      return const ApiKeyValidationResult(
        isValid: false,
        message: 'Se agotó el tiempo de espera esperando al proveedor. Revisa tu conexión.',
      );
    } on http.ClientException catch (e) {
      return ApiKeyValidationResult(isValid: false, message: 'Sin conexión: ${e.message}');
    } catch (e) {
      return ApiKeyValidationResult(isValid: false, message: 'Error inesperado: $e');
    }
  }
}
