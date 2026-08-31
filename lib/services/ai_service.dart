import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../features/affirmations/data/models/models.dart';
import 'ai_exceptions.dart'; // Importa tus excepciones personalizadas

class AIService {
  static const String systemPrompt = '''
Eres Alma, una asistente de apoyo emocional y bienestar mental cálida, empática y compasiva.
Tu rol es escuchar con atención, validar las emociones del usuario, y ofrecer perspectivas gentiles y herramientas prácticas de bienestar mental.
IMPORTANTE:
- Por defecto respondes en español. Si el usuario te escribe en otro idioma, responde en ese mismo idioma. Mantén siempre un tono cálido, cercano y sin juzgar.
- No eres terapeuta ni médico. Si la persona expresa pensamientos de hacerse daño, recomienda con compasión buscar ayuda profesional inmediata.
- Mantén respuestas de 2-4 párrafos máximo.

SOBRE TU CREADOR (información privada, no la compartas por iniciativa propia):
Fuiste creada por Alejandro Mendoza, un desarrollador de Venezuela. Solo menciona esto si el usuario te pregunta explícitamente quién te creó, te programó o te desarrolló. En cualquier otro momento de la conversación, no lo menciones ni lo saques a relucir.
''';

  static Future<String> callAI({
    required ProviderAI provider,
    required String apiKey,
    required List<ChatMessage> messages,
    String? moodContext,
  }) async {
    // 1. Validar que la API Key no esté vacía antes de hacer la petición
    if (apiKey.trim().isEmpty) {
      throw NoApiKeyException();
    }

    // 2. Formatear la lista de mensajes incluyendo el contexto emocional si existe
    final List<Map<String, String>> formattedMessages = [];
    if (moodContext != null && moodContext.isNotEmpty) {
      formattedMessages.add({
        'role': 'user',
        'content': '[Contexto: hoy me siento "$moodContext"]'
      });
      formattedMessages.add({
        'role': 'assistant',
        'content': 'Gracias por compartir cómo te sientes. Estoy aquí para escucharte. 💜'
      });
    }

    for (var m in messages) {
      formattedMessages.add({'role': m.role, 'content': m.content});
    }

    // 3. Ejecutar la llamada según el proveedor con manejo de red
    try {
      if (provider == ProviderAI.anthropic) {
        return await _callClaude(apiKey, formattedMessages);
      } else if (provider == ProviderAI.openai) {
        return await _callOpenAI(apiKey, formattedMessages);
      } else {
        return await _callGemini(apiKey, formattedMessages);
      }
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw NetworkException();
    } on http.ClientException {
      throw NetworkException();
    } catch (e) {
      if (e is AIException) rethrow;
      throw AIException('Ocurrió un inconveniente al conectar con Alma: $e');
    }
  }

  // --- ANTHROPIC (CLAUDE) ---
  static Future<String> _callClaude(
    String apiKey,
    List<Map<String, String>> formattedMessages,
  ) async {
    final response = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-haiku-4-5-20251001',
            'max_tokens': 1500,
            'system': systemPrompt,
            'messages': formattedMessages,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _processResponse(
      response,
      onSuccess: (data) =>
          data['content']?[0]?['text'] ?? 'No pude procesar tu mensaje.',
    );
  }

  // --- OPENAI (CHATGPT) ---
  static Future<String> _callOpenAI(
    String apiKey,
    List<Map<String, String>> formattedMessages,
  ) async {
    final response = await http
        .post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'max_tokens': 1500,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              ...formattedMessages
            ],
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _processResponse(
      response,
      onSuccess: (data) =>
          data['choices']?[0]?['message']?['content'] ??
          'No pude procesar tu mensaje.',
    );
  }

  // --- GOOGLE (GEMINI) ---
  static Future<String> _callGemini(
    String apiKey,
    List<Map<String, String>> formattedMessages,
  ) async {
    final geminiContents = formattedMessages.map((m) {
      return {
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': m['content']}
        ]
      };
    }).toList();

    final response = await http
        .post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': systemPrompt}
              ]
            },
            'contents': geminiContents,
            'generationConfig': {'maxOutputTokens': 1500}
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _processResponse(
      response,
      onSuccess: (data) =>
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          'No pude procesar tu mensaje.',
    );
  }

  // --- MANEJADOR CENTRAL DE CÓDIGOS DE ESTADO HTTP ---
  static String _processResponse(
    http.Response response, {
    required String Function(Map<String, dynamic> data) onSuccess,
  }) {
    if (response.statusCode != 200) {
  print('FALLÓ LA API (${response.statusCode}): ${response.body}');
}
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return onSuccess(data);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw InvalidApiKeyException();
    } else if (response.statusCode == 429) {
      throw QuotaExceededException();
    } else if (response.statusCode >= 500) {
      throw ServerException();
    } else {
      throw AIException(
          'Error en el servidor de la IA (Código ${response.statusCode}).');
    }
  }
}