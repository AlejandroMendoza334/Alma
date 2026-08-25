import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../entities/daily_notification.dart';
import '../repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  // Tope de notificaciones diarias que la UI permite configurar (1-3 veces
  // al día). Se usa para saber qué IDs cancelar cuando la frecuencia baja.
  static const int maxDailyNotifications = 3;

  static const String _channelId = 'alma_daily_channel_id';
  static const String _channelName = 'Afirmaciones Diarias de Alma';
  static const String _channelDescription = 'Canal para recibir tus afirmaciones diarias';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  bool _isInitialized = false;

  NotificationRepositoryImpl({required this.flutterLocalNotificationsPlugin});

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> init() async {
    // Evita reinicializar el plugin en cada llamada (p. ej. cada vez que el
    // usuario abre la pantalla de Ajustes).
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _isInitialized = true;
  }

  @override
  Future<bool> hasPermission() async {
    await init();
    // areNotificationsEnabled() es null en plataformas/versiones donde no
    // aplica (ej. Android <13, o iOS) -> ahí no hace falta pedir permiso.
    return await _android?.areNotificationsEnabled() ?? true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final granted = await _android?.requestNotificationsPermission();
    if (kDebugMode) {
      debugPrint('[Notifications] Permiso de notificaciones concedido: $granted');
    }
    return granted ?? true;
  }

  @override
  Future<List<ScheduledNotificationResult>> scheduleDailyNotifications(
    List<DailyNotification> notifications,
  ) async {
    await init();

    // Cancela los IDs que sobran de una frecuencia anterior más alta (p. ej.
    // si el usuario baja de 3 a 1 notificación al día, los ids 2 y 3
    // quedarían programados para siempre si no se cancelan explícitamente).
    for (int id = notifications.length + 1; id <= maxDailyNotifications; id++) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }

    final results = <ScheduledNotificationResult>[];
    for (int i = 0; i < notifications.length; i++) {
      results.add(await _scheduleOne(id: i + 1, notification: notifications[i]));
    }
    return results;
  }

  @override
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<ScheduledNotificationResult> _scheduleOne({
    required int id,
    required DailyNotification notification,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      // El ícono pequeño de la barra de estado tiene que quedar como
      // @mipmap/ic_launcher (Android lo fuerza a silueta blanca sin
      // importar qué imagen le pongas). El logo a color de Alma va en el
      // ícono grande, que sí se muestra tal cual dentro de la notificación.
      largeIcon: const DrawableResourceAndroidBitmap('ic_notification_large'),
      // Esto permite que el texto de la afirmación se despliegue bien en la barra de tareas
      styleInformation: BigTextStyleInformation(
        notification.body,
        htmlFormatBigText: false,
        contentTitle: notification.title,
        htmlFormatContentTitle: false,
      ),
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

    final result = _nextInstanceOfTime(notification.hour, notification.minute);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        notification.title,
        notification.body,
        result.$1,
        notificationDetails,
        // inexactAllowWhileIdle NO requiere el permiso especial
        // SCHEDULE_EXACT_ALARM (Android 12+) y basta para un recordatorio
        // diario: Android puede disparar la notificación con algunos
        // minutos de margen incluso en Doze mode.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // se repite todos los días a la misma hora
      );
      if (kDebugMode) {
        debugPrint('[Notifications] Programada id=$id para ${result.$1} (tz: ${tz.local.name})');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Notifications] Error al programar id=$id: $e\n$st');
      }
      rethrow;
    }

    return ScheduledNotificationResult(fireAt: result.$1, isToday: result.$2);
  }

  // Si la hora elegida ya pasó hoy (o está a menos de 30s de "ahora"), la
  // programamos para mañana en vez de dispararla casi de inmediato.
  (tz.TZDateTime, bool) _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    final isToday = scheduledDate.isAfter(now.add(const Duration(seconds: 30)));
    if (!isToday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return (scheduledDate, isToday);
  }
}
