import '../entities/affirmation.dart';
import '../repositories/affirmation_repository.dart';

class GetAffirmationsByCategory {
  final AffirmationRepository repository;

  GetAffirmationsByCategory(this.repository);

  Future<List<Affirmation>> call(String category) {
    return repository.getAffirmationsByCategory(category);
  }
}