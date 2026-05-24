import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tasks_table.dart';

part 'tasks_dao.g.dart';

/// Boards cuyas tareas nuevas se insertan al principio (posición mínima - 1).
const _topInsertBoards = {'board-hoy'};

/// Al mover una tarea a Hoy la programación se cancela (ya está «hoy»).
/// En cualquier otro destino la programación se preserva.
const _clearScheduleOnMoveBoards = {'board-hoy'};

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  Stream<List<TaskData>> watchTasksByBoard(String boardId) {
    return (select(tasks)
      ..where((t) => t.boardId.equals(boardId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.desc(t.isFrog),
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
        (t) => OrderingTerm.asc(t.position),
      ]))
        .watch();
  }

  Stream<List<TaskData>> watchScheduledTasks() {
    return (select(tasks)
      ..where((t) => t.scheduledDate.isNotNull() & t.isDone.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .watch();
  }

  Future<TaskData?> getTaskById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<TaskData?> watchTaskById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<int> countPendingByBoard(String boardId) async {
    final count = tasks.id.count();
    final query = selectOnly(tasks)
      ..addColumns([count])
      ..where(tasks.boardId.equals(boardId) & tasks.isDone.equals(false));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ─── Helpers de posición ──────────────────────────────────────────────────

  /// Devuelve la posición mínima actual del board, o 0 si está vacío.
  Future<int> getMinPosition(String boardId) async {
    final minPos = tasks.position.min();
    final query = selectOnly(tasks)
      ..addColumns([minPos])
      ..where(tasks.boardId.equals(boardId));
    final result = await query.getSingle();
    return result.read(minPos) ?? 0;
  }

  /// Devuelve la posición máxima actual del board, o -1 si está vacío.
  Future<int> getMaxPosition(String boardId) async {
    final maxPos = tasks.position.max();
    final query = selectOnly(tasks)
      ..addColumns([maxPos])
      ..where(tasks.boardId.equals(boardId));
    final result = await query.getSingle();
    return result.read(maxPos) ?? -1;
  }

  /// Calcula la posición de inserción según la regla del board:
  ///  • Boards «ahora» (board-hoy): minPosition - 1  → aparece arriba.
  ///  • Boards «algún día» (To Do): maxPosition + 1  → aparece abajo.
  Future<int> nextInsertPosition(String boardId) async {
    if (_topInsertBoards.contains(boardId)) {
      return (await getMinPosition(boardId)) - 1;
    } else {
      return (await getMaxPosition(boardId)) + 1;
    }
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────

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

  /// Mueve la tarea al tablero destino.
  ///
  /// - `scheduledDate` se preserva salvo que el destino sea `board-hoy`,
  ///   donde la programación ya no tiene sentido (la tarea ya está «hoy»).
  /// - `isFrog` se resetea siempre: la rana es contexto del tablero origen.
  Future<void> moveToBoard(
      String taskId, String targetBoardId, int position) {
    final clearSchedule =
        _clearScheduleOnMoveBoards.contains(targetBoardId);

    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        boardId: Value(targetBoardId),
        isFrog: const Value(false),
        position: Value(position),
        // Solo borramos scheduledDate si el destino es Hoy
        scheduledDate:
            clearSchedule ? const Value(null) : const Value.absent(),
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
          TasksCompanion(
              position: Value(entry.value), updatedAt: Value(now)),
        );
      }
    });
  }

  Future<int> clearCompleted(String boardId) {
    return (delete(tasks)
          ..where(
              (t) => t.boardId.equals(boardId) & t.isDone.equals(true)))
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

  /// Mueve a «Hoy» todas las tareas cuya fecha programada ya llegó.
  /// Las inserta al principio del board (minPosition - 1, decrementando
  /// para cada tarea para preservar su orden relativo original).
  Future<int> moveScheduledTasksToToday(
      String todayBoardId, int nowMs) async {
    final due = await (select(tasks)
          ..where((t) =>
              t.scheduledDate.isNotNull() &
              t.scheduledDate.isSmallerOrEqualValue(nowMs) &
              t.boardId.isNotValue(todayBoardId) &
              t.isDone.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();

    if (due.isEmpty) return 0;

    // Reservamos posiciones al principio: minPos-1, minPos-2, …
    // (orden invertido para que la más antigua quede más arriba).
    final minPos = await getMinPosition(todayBoardId);

    await transaction(() async {
      for (var i = 0; i < due.length; i++) {
        final newPosition = minPos - (due.length - i);
        await (update(tasks)..where((t) => t.id.equals(due[i].id))).write(
          TasksCompanion(
            boardId: Value(todayBoardId),
            scheduledDate: const Value(null),
            position: Value(newPosition),
            updatedAt: Value(nowMs),
          ),
        );
      }
    });

    return due.length;
  }
}
