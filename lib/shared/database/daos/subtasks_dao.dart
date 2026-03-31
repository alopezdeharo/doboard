import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/subtasks_table.dart';

part 'subtasks_dao.g.dart';

@DriftAccessor(tables: [Subtasks])
class SubtasksDao extends DatabaseAccessor<AppDatabase>
    with _$SubtasksDaoMixin {
  SubtasksDao(super.db);

  // ─── Lecturas ──────────────────────────────────────────────────────────────

  /// Stream de subtareas de una tarea, ordenadas por posición.
  Stream<List<SubtaskData>> watchSubtasksByTask(String taskId) {
    return (select(subtasks)
      ..where((s) => s.taskId.equals(taskId))
      ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .watch();
  }

  /// Lista simple (sin stream) para operaciones puntuales.
  Future<List<SubtaskData>> getSubtasksByTask(String taskId) {
    return (select(subtasks)
      ..where((s) => s.taskId.equals(taskId))
      ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
  }

  // ─── Escrituras ────────────────────────────────────────────────────────────

  Future<void> insertSubtask(SubtasksCompanion subtask) {
    return into(subtasks).insert(subtask);
  }

  Future<bool> updateSubtask(SubtasksCompanion subtask) {
    return update(subtasks).replace(subtask);
  }

  Future<void> toggleDone(String id, {required bool isDone}) {
    return (update(subtasks)..where((s) => s.id.equals(id))).write(
      SubtasksCompanion(isDone: Value(isDone)),
    );
  }

  Future<int> deleteSubtask(String id) {
    return (delete(subtasks)..where((s) => s.id.equals(id))).go();
  }

  Future<int> deleteAllSubtasks(String taskId) {
    return (delete(subtasks)..where((s) => s.taskId.equals(taskId))).go();
  }

  Future<void> reorderSubtasks(Map<String, int> positions) async {
    await transaction(() async {
      for (final entry in positions.entries) {
        await (update(subtasks)..where((s) => s.id.equals(entry.key))).write(
          SubtasksCompanion(position: Value(entry.value)),
        );
      }
    });
  }
}