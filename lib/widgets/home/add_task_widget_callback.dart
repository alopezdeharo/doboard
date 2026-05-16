import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import 'add_task_widget_keys.dart';
import 'widget_task_creator.dart';

const _androidProvider =
    'com.adrisdev.doboard.AddTaskWidgetProvider';

const _validBoardIds = {
  'board-rapidas',
  'board-calma',
  'board-prisa',
};

/// Invocado desde el widget de escritorio (Android).
@pragma('vm:entry-point')
FutureOr<void> addTaskWidgetCallback(Uri? uri) async {
  if (uri == null || uri.host != 'widget') return;

  final path = uri.path;
  if (path != '/add') return;

  final boardId = uri.queryParameters['boardId'];
  final title = uri.queryParameters['title'];
  if (boardId == null ||
      title == null ||
      !_validBoardIds.contains(boardId) ||
      title.trim().isEmpty) {
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();

  try {
    await WidgetTaskCreator.create(boardId: boardId, title: title);
    await _showTemporaryFeedback('✓ Añadida');
  } catch (_) {
    await _showTemporaryFeedback('Error al guardar');
  }
}

Future<void> _showTemporaryFeedback(String message) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  await HomeWidget.saveWidgetData<String>(
    AddTaskWidgetProviderKeys.lastFeedback,
    message,
  );
  await HomeWidget.saveWidgetData<int>(
    AddTaskWidgetProviderKeys.lastFeedbackAt,
    now,
  );
  await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);

  await Future<void>.delayed(const Duration(milliseconds: 2600));
  await HomeWidget.saveWidgetData<String?>(
    AddTaskWidgetProviderKeys.lastFeedback,
    null,
  );
  await HomeWidget.saveWidgetData<int?>(
    AddTaskWidgetProviderKeys.lastFeedbackAt,
    null,
  );
  await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
}
