import '../entities/affirmation.dart';
import '../repositories/affirmation_repository.dart';

class GetDailyAffirmation {
  final AffirmationRepository repository;

  GetDailyAffirmation(this.repository);
  

  Future<Affirmation> call() async {
    return await repository.getDailyAffirmation();
    
  }
}