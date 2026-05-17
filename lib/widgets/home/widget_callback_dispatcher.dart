import 'dart:async';

import 'add_task_widget_callback.dart';
import 'today_tasks_widget_callback.dart';

/// Punto de entrada único para todos los callbacks de widgets de escritorio.
///
/// `home_widget` solo admite un callback registrado
/// (`HomeWidget.registerInteractivityCallback`), así que este dispatcher
/// enruta cada URI al handler correcto según el path:
///
///  • `/add`           → [addTaskWidgetCallback]  (widget «Añadir tarea»)
///  • `/toggle_today`  → [todayTasksWidgetCallback] (widget «Hoy»)
///  • `/add_today`     → [todayTasksWidgetCallback] (widget «Hoy»)
@pragma('vm:entry-point')
FutureOr<void> widgetCallbackDispatcher(Uri? uri) async {
  if (uri == null || uri.host != 'widget') return;

  switch (uri.path) {
    case '/add':
      return addTaskWidgetCallback(uri);
    case '/toggle_today':
    case '/add_today':
      return todayTasksWidgetCallback(uri);
  }
}
