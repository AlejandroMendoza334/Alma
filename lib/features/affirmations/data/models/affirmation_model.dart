import '../../domain/entities/affirmation.dart';

class AffirmationModel extends Affirmation {
  const AffirmationModel({
    required super.id,
    required super.text,
    required super.category,
    super.author, // Opcional si la clase padre lo permite
  });

  factory AffirmationModel.fromJson(Map<String, dynamic> json) {
    return AffirmationModel(
      // Convierte el id a String por si viene como int desde el JSON (1, 2, 3...)
      id: json['id']?.toString() ?? '',
      text: json['text'] as String? ?? json['texto'] as String? ?? '',
      category: json['category'] as String? ?? json['categoria'] as String? ?? '',
      author: json['author'] as String? ?? json['autor'] as String? ?? 'Anónimo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'author': author ?? '',
    };
  }
}