import '../entities/daily_notification.dart';

abstract class NotificationRepository {
  Future<void> init();

  /// true si el usuario ya concedió el permiso de notificaciones (Android 13+
  /// lo pide en runtime; en versiones anteriores siempre es true).
  Future<bool> hasPermission();

  /// Pide el permiso al sistema. Devuelve el resultado (o el estado actual
  /// si el SO no necesita pedirlo).
  Future<bool> requestPermission();

  /// Programa exactamente el conjunto de notificaciones recibido: cancela
  /// cualquier notificación diaria programada antes que ya no esté en la
  /// lista (p. ej. si la frecuencia bajó de 3 a 1 al día) para no dejar
  /// alarmas huérfanas sonando.
  Future<List<ScheduledNotificationResult>> scheduleDailyNotifications(
    List<DailyNotification> notifications,
  );

  /// Cancela todas las notificaciones diarias programadas.
  Future<void> cancelAll();
}
