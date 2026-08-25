import 'package:http/http.dart' as http;
import 'dart:convert';
import '../features/affirmations/data/models/models.dart';

class ApiValidationService {
  static Future<bool> validateKey(ProviderAI provider, String apiKey) async {
    if (apiKey.trim().isEmpty) return false;

    try {
      switch (provider) {
        case ProviderAI.openai:
          final res = await http.get(
            Uri.parse('https://api.openai.com/v1/models'),
            headers: {'Authorization': 'Bearer $apiKey'},
          );
          return res.statusCode == 200;

        case ProviderAI.gemini:
          final res = await http.get(
            Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
          );
          return res.statusCode == 200;

        case ProviderAI.anthropic:
          final res = await http.post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': 'claude-3-haiku-20240307',
              'max_tokens': 1,
              'messages': [{'role': 'user', 'content': 'hi'}]
            }),
          );
          return res.statusCode == 200;
      }
    } catch (_) {
      return false;
    }
  }
}