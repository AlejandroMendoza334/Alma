import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mind_flow/features/affirmations/domain/entities/affirmation.dart';
import 'package:mind_flow/features/affirmations/domain/repositories/affirmation_repository.dart';
import 'package:mind_flow/features/affirmations/data/models/affirmation_model.dart';

class AffirmationRepositoryImpl implements AffirmationRepository {
  final String jsonPath;

  AffirmationRepositoryImpl({this.jsonPath = 'assets/data/afirmaciones.json'});

  @override
  Future<List<Affirmation>> getAffirmations() async {
    // 1. Leemos el archivo JSON desde los assets
    final String jsonString = await rootBundle.loadString(jsonPath);
    
    // 2. Decodificamos (tu JSON es una Lista directa, no un Map)
    final dynamic decodedData = json.decode(jsonString);
    
    final List<dynamic> list;
    if (decodedData is Map<String, dynamic>) {
      list = decodedData['afirmaciones'] as List<dynamic>? ?? [];
    } else if (decodedData is List) {
      list = decodedData;
    } else {
      list = [];
    }

    // 3. Mapeamos cada elemento a nuestro AffirmationModel
    return list
        .map((item) => AffirmationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Affirmation>> getAffirmationsByCategory(String category) async {
    final allAffirmations = await getAffirmations();
    return allAffirmations
      .where((aff) => aff.category == category)
      .toList();
  }

  @override
  Future<Affirmation> getDailyAffirmation() async {
    final allAffirmations = await getAffirmations();
    if (allAffirmations.isEmpty) {
      // Fallback por seguridad si la lista estuviera vacía
      throw Exception('No hay afirmaciones disponibles');
    }
    
    // Selecciona una afirmación basada en el día del año actual
    final int dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final int index = dayOfYear % allAffirmations.length;

    return allAffirmations[index];
  }
}