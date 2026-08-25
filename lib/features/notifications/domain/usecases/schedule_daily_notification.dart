import 'package:flutter/material.dart';
import '../../../affirmations/domain/entities/affirmation.dart';
import '../../../affirmations/domain/usecases/get_daily_affirmation.dart';
import '../repositories/notification_repository.dart';

class ScheduleDailyNotification {
  final NotificationRepository notificationRepository;
  final GetDailyAffirmation getDailyAffirmation;

  ScheduleDailyNotification({
    required this.notificationRepository,
    required this.getDailyAffirmation,
  });

  Future<void> call({required List<TimeOfDay> times}) async {
    final Affirmation affirmation = await getDailyAffirmation();

    // Programamos cada hora seleccionada asignándole un ID único (ej: ID 1, 2, 3...)
    for (int i = 0; i < times.length; i++) {
      final time = times[i];
      await notificationRepository.scheduleDailyNotification(
        id: i + 1, // ID único para cada notificación diaria
        title: 'Tu Afirmación del Día 🌙',
        body: affirmation.text,
        hour: time.hour,
        minute: time.minute,
      );
    }
  }
}