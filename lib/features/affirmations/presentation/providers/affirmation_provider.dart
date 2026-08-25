import 'package:flutter/foundation.dart';
import '../../domain/entities/affirmation.dart';
import '../../domain/usecases/get_daily_affirmation.dart';
import '../../domain/usecases/get_affirmations_by_category.dart';

class AffirmationProvider extends ChangeNotifier {
  final GetDailyAffirmation getDailyAffirmation;
  final GetAffirmationsByCategory getAffirmationsByCategory;

  AffirmationProvider({
    required this.getDailyAffirmation,
    required this.getAffirmationsByCategory,
  });

  Affirmation? _dailyAffirmation;
  List<Affirmation> _categoryAffirmations = [];
  bool _isLoading = false;
  Object? _error;

  // Getters públicos
  Affirmation? get dailyAffirmation => _dailyAffirmation;
  List<Affirmation> get categoryAffirmations => _categoryAffirmations;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  /// Carga la afirmación principal del día
  Future<void> loadDailyAffirmation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dailyAffirmation = await getDailyAffirmation();
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtra afirmaciones por la categoría seleccionada
  Future<void> loadByCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categoryAffirmations = await getAffirmationsByCategory(category);
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}