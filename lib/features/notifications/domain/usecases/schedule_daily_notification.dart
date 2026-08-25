import 'package:flutter/material.dart';
import '../../../affirmations/domain/entities/affirmation.dart';
import '../../../affirmations/domain/usecases/get_daily_affirmation.dart';
import '../entities/daily_notification.dart';
import '../repositories/notification_repository.dart';

class ScheduleDailyNotification {
  final NotificationRepository notificationRepository;
  final GetDailyAffirmation getDailyAffirmation;

  ScheduleDailyNotification({
    required this.notificationRepository,
    required this.getDailyAffirmation,
  });

  Future<List<ScheduledNotificationResult>> call({required List<TimeOfDay> times}) async {
    final notifications = <DailyNotification>[];

    for (final time in times) {
      // Obtenemos una afirmación (puedes llamar al caso de uso dentro del loop
      // si tu lógica genera o rota frases, o mantener una si prefieres la misma)
      final Affirmation affirmation = await getDailyAffirmation();

      notifications.add(DailyNotification(
        hour: time.hour,
        minute: time.minute,
        title: 'Tu Afirmación del Día 🌙',
        body: affirmation.text, // El texto de la afirmación en la barra de tareas
      ));
    }

    return notificationRepository.scheduleDailyNotifications(notifications);
  }
}
