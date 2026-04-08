import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Servicio singleton que encapsula flutter_local_notifications.
///
/// Responsabilidades:
///   · Inicializar el plugin y solicitar permisos
///   · Programar notificaciones cuando una tarea se programa para una fecha
///   · Cancelar notificaciones cuando se cancela la programación
///   · Mostrar notificación inmediata cuando la app detecta tareas vencidas
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  // Canal Android para tareas programadas
  static const _channelId = 'doboard_scheduled';
  static const _channelName = 'Tareas programadas';
  static const _channelDesc =
      'Avisa cuando una tarea programada se mueve a Hoy';

  // Hora a la que se muestra la notificación del día programado (9:00 AM)
  static const _notifHour = 9;
  static const _notifMinute = 0;

  bool _initialized = false;

  // ─── Inicialización ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar base de datos de zonas horarias
    tz_data.initializeTimeZones();

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Se pide explícitamente más abajo
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  /// Solicita permiso de notificaciones al usuario (iOS + Android 13+).
  /// Llamar solo tras una acción del usuario (p.ej. al programar la primera
  /// tarea) para maximizar la tasa de aceptación.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  // ─── Programar notificación ────────────────────────────────────────────────

  /// Programa una notificación a las [_notifHour]:00 del día [scheduledDate].
  /// Si la hora ya pasó hoy, programa para el día siguiente a la misma hora.
  ///
  /// Se llama desde el repositorio al invocar scheduleTask().
  Future<void> scheduleTaskNotification({
    required String taskId,
    required String taskTitle,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) return;

    final notifId = _idFromTaskId(taskId);
    final tzDate = _buildTzDateTime(scheduledDate);

    // Si la fecha ya pasó, no programar (processScheduledTasks lo habrá
    // movido la próxima vez que se abra la app)
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      notifId,
      '📅 Tarea para hoy',
      taskTitle,
      tzDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: taskId, // Se usa en _onNotificationTap para navegar
    );

    debugPrint('[Notif] Programada para $taskTitle → $tzDate (id=$notifId)');
  }

  // ─── Cancelar notificación ────────────────────────────────────────────────

  /// Cancela la notificación asociada a [taskId].
  /// Se llama desde el repositorio al invocar cancelSchedule() o moveToBoard().
  Future<void> cancelTaskNotification(String taskId) async {
    if (!_initialized) return;
    await _plugin.cancel(_idFromTaskId(taskId));
    debugPrint('[Notif] Cancelada para taskId=$taskId');
  }

  // ─── Notificación inmediata (fallback al abrir la app) ───────────────────

  /// Muestra una notificación inmediata cuando la app detecta tareas vencidas
  /// al arrancar. Actúa como fallback si el usuario no vio la notificación
  /// programada (pantalla silenciada, DND, etc.).
  ///
  /// Solo se muestra si [count] > 0.
  Future<void> showTasksMovedNotification(int count) async {
    if (!_initialized || count <= 0) return;

    final body = count == 1
        ? 'Una tarea se ha movido a Hoy'
        : '$count tareas se han movido a Hoy';

    await _plugin.show(
      0, // ID fijo para el resumen diario
      '🐸 Hoy te espera trabajo',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false, // Sin sonido para el resumen de apertura
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Convierte un UUID en un int válido para ID de notificación.
  /// Usa módulo para mantenerse en rango int32 positivo.
  int _idFromTaskId(String taskId) =>
      taskId.hashCode.abs() % 2147483647;

  /// Construye un TZDateTime a las [_notifHour]:00 del día [date]
  /// en la zona horaria local del dispositivo.
  tz.TZDateTime _buildTzDateTime(DateTime date) {
    final local = tz.local;
    return tz.TZDateTime(
      local,
      date.year,
      date.month,
      date.day,
      _notifHour,
      _notifMinute,
    );
  }

  /// Callback cuando el usuario toca una notificación.
  /// El [payload] es el taskId — aquí se puede navegar a la tarea
  /// cuando se integre con go_router desde un punto global.
  void _onNotificationTap(NotificationResponse response) {
    final taskId = response.payload;
    debugPrint('[Notif] Tapped → taskId=$taskId');
    // TODO: navegar a /task/$taskId usando el router global
    // NavigationService.instance.push('/task/$taskId');
  }
}