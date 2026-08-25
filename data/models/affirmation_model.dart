import '../../domain/entities/affirmation.dart';

class AffirmationModel extends Affirmation {
  const AffirmationModel({
    required String id,
    required String text,
    required String category,
    required String author,
  }) : super(
          id: id,
          text: text,
          category: category,
          author: author,
        );

  factory AffirmationModel.fromJson(Map<String, dynamic> json) {
    return AffirmationModel(
      id: json['id'] as String? ?? '',
      text: json['texto'] as String? ?? '',
      category: json['categoria'] as String? ?? '',
      author: json['autor'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'texto': text,
      'categoria': category,
      'autor': author
    };
  }
}