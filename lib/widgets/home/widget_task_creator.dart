import 'package:doboard/core/utils/automation_engine.dart';
import 'package:doboard/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:doboard/shared/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Crea una tarea desde el callback del widget (sin Riverpod).
class WidgetTaskCreator {
  static const _kAutomations = 'automations_enabled';

  static Future<void> create({
    required String boardId,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    final db = AppDatabase();
    try {
      final prefs = await SharedPreferences.getInstance();
      final automations = prefs.getBool(_kAutomations) ?? true;
      final keyword =
          automations ? AutomationEngine.instance.detect(trimmed) : null;

      await TaskRepositoryImpl(db).createTask(
        id: const Uuid().v4(),
        boardId: boardId,
        title: trimmed,
        detectedKeyword: keyword,
      );
    } finally {
      await db.close();
    }
  }
}
