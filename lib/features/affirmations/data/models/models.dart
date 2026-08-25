enum ProviderAI { anthropic, openai, gemini }
enum ViewState { home, mood, chat, settings }

class Affirmation {
  final int id;
  final String text;
  final String category;

  Affirmation({required this.id, required this.text, required this.category});

  factory Affirmation.fromJson(Map<String, dynamic> json) {
    return Affirmation(
      id: json['id'],
      text: json['text'],
      category: json['category'],
    );
  }
}

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});
}