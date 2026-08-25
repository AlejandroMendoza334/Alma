class Affirmation {
  final String id;
  final String text;
  final String category;
  final String? author; // Agrega esta línea si no existía

  const Affirmation({
    required this.id,
    required this.text,
    required this.category,
    this.author,
  });
}