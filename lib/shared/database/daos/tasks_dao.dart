import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tasks_table.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  Stream<List<TaskData>> watchTasksByBoard(String boardId) {
    return (select(tasks)
      ..where((t) => t.boardId.equals(boardId))
      ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.isFrog),
            (t) => OrderingTerm.desc(t.priority),
            (t) => OrderingTerm.asc(t.position),
      ]))
        .watch();
  }

  Stream<List<TaskData>> watchPendingTasksByBoard(String boardId) {
    return (select(tasks)
      ..where((t) => t.boardId.equals(boardId) & t.isDone.equals(false))
      ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.isFrog),
            (t) => OrderingTerm.desc(t.priority),
            (t) => OrderingTerm.asc(t.position),
      ]))
        .watch();
  }

  Future<TaskData?> getTaskById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> countPendingByBoard(String boardId) async {
    final count = tasks.id.count();
    final query = selectOnly(tasks)
      ..addColumns([count])
      ..where(tasks.boardId.equals(boardId) & tasks.isDone.equals(false));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<void> insertTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  Future<bool> updateTask(TasksCompanion task) {
    return update(tasks).replace(task);
  }

  Future<int> deleteTask(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> toggleDone(String id, {required bool isDone}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isDone: Value(isDone),
        completedAt: Value(isDone ? now : null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> moveToBoard(String taskId, String targetBoardId) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        boardId: Value(targetBoardId),
        isFrog: const Value(false),
        position: const Value(0),
        scheduledDate: const Value(null), // limpiar fecha al mover manualmente
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setFrog(String taskId, String boardId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await transaction(() async {
      await (update(tasks)..where((t) => t.boardId.equals(boardId))).write(
        TasksCompanion(isFrog: const Value(false), updatedAt: Value(now)),
      );
      await (update(tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(isFrog: const Value(true), updatedAt: Value(now)),
      );
    });
  }

  Future<void> removeFrog(String taskId) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        isFrog: const Value(false),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> reorderTasks(Map<String, int> positions) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await transaction(() async {
      for (final entry in positions.entries) {
        await (update(tasks)..where((t) => t.id.equals(entry.key))).write(
          TasksCompanion(position: Value(entry.value), updatedAt: Value(now)),
        );
      }
    });
  }

  Future<int> clearCompleted(String boardId) {
    return (delete(tasks)
      ..where((t) => t.boardId.equals(boardId) & t.isDone.equals(true)))
        .go();
  }

  Future<void> duplicateTask(TaskData original, String newId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return into(tasks).insert(TasksCompanion(
      id: Value(newId),
      boardId: Value(original.boardId),
      title: Value('${original.title} (copia)'),
      content: Value(original.content),
      priority: Value(original.priority),
      position: Value(original.position + 1),
      isDone: const Value(false),
      isFrog: const Value(false),
      isPinned: const Value(false),
      detectedKeyword: Value(original.detectedKeyword),
      parentTaskTitle: Value(original.parentTaskTitle),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  /// Devuelve tareas cuya fecha programada ya ha llegado y no están en "Hoy".
  Future<List<TaskData>> getTasksDueToMove(
      String todayBoardId, int nowMs) async {
    return (select(tasks)
      ..where((t) =>
      t.scheduledDate.isNotNull() &
      t.scheduledDate.isSmallerOrEqualValue(nowMs) &
      t.boardId.isNotValue(todayBoardId) &
      t.isDone.equals(false)))
        .get();
  }

  /// Mueve las tareas programadas a "Hoy" (se llama al abrir la app).
  Future<int> moveScheduledTasksToToday(
      String todayBoardId, int nowMs) async {
    return (update(tasks)
      ..where((t) =>
      t.scheduledDate.isNotNull() &
      t.scheduledDate.isSmallerOrEqualValue(nowMs) &
      t.boardId.isNotValue(todayBoardId) &
      t.isDone.equals(false)))
        .write(TasksCompanion(
      boardId: Value(todayBoardId),
      scheduledDate: const Value(null),
      position: const Value(0),
      updatedAt: Value(nowMs),
    ));
  }
}