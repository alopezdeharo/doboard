import 'dart:async';

import 'package:doboard/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:doboard/shared/database/app_database.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/automation_engine.dart';
import 'today_tasks_widget_keys.dart';
import 'today_tasks_widget_updater.dart';

const _androidProvider = 'com.adrisdev.doboard.TodayTasksWidgetProvider';
const _kAutomations = 'automations_enabled';

/// Gestiona las acciones del widget «Tareas de Hoy»:
///
///  • `/toggle_today?taskId=...&isDone=true|false`
///    Marca la tarea como completada / pendiente y refresca el widget.
///
///  • `/add_today?title=...`
///    Crea una tarea nueva en `board-hoy` y refresca el widget.
@pragma('vm:entry-point')
FutureOr<void> todayTasksWidgetCallback(Uri uri) async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  try {
    final repo = TaskRepositoryImpl(db);

    switch (uri.path) {
      case '/toggle_today':
        final taskId = uri.queryParameters['taskId'];
        final isDone = uri.queryParameters['isDone'] == 'true';
        if (taskId == null || taskId.isEmpty) return;

        await repo.toggleDone(taskId, isDone: isDone);

        // Actualizar widget inmediatamente tras el toggle.
        final tasksAfterToggle = await repo.watchTasksByBoard('board-hoy').first;
        await TodayTasksWidgetUpdater.update(tasksAfterToggle);

      case '/add_today':
        final title = uri.queryParameters['title']?.trim() ?? '';
        if (title.isEmpty) return;

        final prefs = await SharedPreferences.getInstance();
        final automations = prefs.getBool(_kAutomations) ?? true;
        final keyword =
            automations ? AutomationEngine.instance.detect(title) : null;

        await repo.createTask(
          id: const Uuid().v4(),
          boardId: 'board-hoy',
          title: title,
          detectedKeyword: keyword,
        );

        // 1. Actualizar el widget con la lista nueva ANTES del feedback,
        //    así la tarea aparece de inmediato sin esperar los 2.6 s.
        final tasksAfterAdd = await repo.watchTasksByBoard('board-hoy').first;
        await TodayTasksWidgetUpdater.update(tasksAfterAdd);

        // 2. Mostrar feedback en paralelo (fire-and-forget): no bloqueamos
        //    el hilo principal ni retrasamos la lista ya actualizada.
        unawaited(_showFeedback('✓ Añadida a Hoy'));

      default:
        return;
    }
  } finally {
    await db.close();
  }
}

Future<void> _showFeedback(String message) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  await HomeWidget.saveWidgetData<String>(
    TodayTasksWidgetProviderKeys.lastFeedback,
    message,
  );
  await HomeWidget.saveWidgetData<int>(
    TodayTasksWidgetProviderKeys.lastFeedbackAt,
    now,
  );
  await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);

  await Future<void>.delayed(const Duration(milliseconds: 2600));

  await HomeWidget.saveWidgetData<String?>(
    TodayTasksWidgetProviderKeys.lastFeedback,
    null,
  );
  await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
}
