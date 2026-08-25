import '../entities/affirmation.dart';

abstract class AffirmationRepository {
  Future<List<Affirmation>> getAffirmations();
  Future<List<Affirmation>> getAffirmationsByCategory(String category);
  Future<Affirmation> getDailyAffirmation(); 
}