class DailyNotification {
  final int hour;
  final int minute;
  final String title;
  final String body;

  const DailyNotification({
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
  });
}

/// Resultado de programar una [DailyNotification]: cuándo va a sonar
/// realmente y si eso cae hoy o hasta mañana (si la hora elegida ya pasó).
class ScheduledNotificationResult {
  final DateTime fireAt;
  final bool isToday;

  const ScheduledNotificationResult({required this.fireAt, required this.isToday});
}
