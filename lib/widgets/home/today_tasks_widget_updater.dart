import 'dart:convert';

import 'package:doboard/features/tasks/domain/entities/task.dart';
import 'package:home_widget/home_widget.dart';

import 'today_tasks_widget_keys.dart';

const _androidProvider = 'com.adrisdev.doboard.TodayTasksWidgetProvider';

/// Serializa la lista de tareas de «Hoy» en SharedPreferences y
/// dispara una actualización del widget de escritorio.
///
/// Llámalo cada vez que las tareas de [boardId] = 'board-hoy' cambien:
///  - desde el callback de fondo (toggle / add_today)
///  - desde la app al abrirse o reanudarse
class TodayTasksWidgetUpdater {
  const TodayTasksWidgetUpdater._();

  static Future<void> update(List<Task> tasks) async {
    final json = jsonEncode(
      tasks
          .map(
            (t) => {
              'id': t.id,
              'title': t.title,
              'isDone': t.isDone,
              'isFrog': t.isFrog,
              'priority': t.priority.value,
            },
          )
          .toList(),
    );

    await HomeWidget.saveWidgetData<String>(
      TodayTasksWidgetProviderKeys.tasksJson,
      json,
    );
    await HomeWidget.saveWidgetData<int>(
      TodayTasksWidgetProviderKeys.taskCount,
      tasks.length,
    );
    await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
  }
}
