import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tasks_table.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  // ─── Lecturas ──────────────────────────────────────────────────────────────

  /// Stream de tareas de un tablero, ordenadas por:
  /// 1. Fijadas primero (isPinned DESC)
  /// 2. Rana primero (isFrog DESC)
  /// 3. Prioridad descendente
  /// 4. Posición manual
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

  /// Stream de tareas pendientes de un tablero (sin completadas).
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

  /// Obtiene una tarea por ID.
  Future<TaskData?> getTaskById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Cuenta de tareas pendientes por tablero (para el badge del dot nav).
  Future<int> countPendingByBoard(String boardId) async {
    final count = tasks.id.count();
    final query = selectOnly(tasks)
      ..addColumns([count])
      ..where(tasks.boardId.equals(boardId) & tasks.isDone.equals(false));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ─── Escrituras ────────────────────────────────────────────────────────────

  Future<void> insertTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  Future<bool> updateTask(TasksCompanion task) {
    return update(tasks).replace(task);
  }

  Future<int> deleteTask(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Marca o desmarca como completada. Registra completedAt si done=true.
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

  /// Mueve una tarea a otro tablero (cambia boardId y resetea posición).
  Future<void> moveToBoard(String taskId, String targetBoardId) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        boardId: Value(targetBoardId),
        isFrog: const Value(false), // la rana no viaja entre tableros
        position: const Value(0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Asigna la rana del día: quita la rana a todas las tareas del tablero
  /// y la asigna solo a la tarea indicada.
  Future<void> setFrog(String taskId, String boardId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await transaction(() async {
      // Quitar rana a todas las del tablero
      await (update(tasks)..where((t) => t.boardId.equals(boardId))).write(
        TasksCompanion(isFrog: const Value(false), updatedAt: Value(now)),
      );
      // Asignar rana a la tarea elegida
      await (update(tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(isFrog: const Value(true), updatedAt: Value(now)),
      );
    });
  }

  /// Elimina la rana de una tarea (toggle off).
  Future<void> removeFrog(String taskId) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        isFrog: const Value(false),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Actualiza las posiciones de varias tareas en una transacción.
  /// Se usa después de reordenar por D&D.
  Future<void> reorderTasks(Map<String, int> positions) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await transaction(() async {
      for (final entry in positions.entries) {
        await (update(tasks)..where((t) => t.id.equals(entry.key))).write(
          TasksCompanion(
            position: Value(entry.value),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Elimina todas las tareas completadas de un tablero.
  Future<int> clearCompleted(String boardId) {
    return (delete(tasks)
      ..where((t) => t.boardId.equals(boardId) & t.isDone.equals(true)))
        .go();
  }

  /// Duplica una tarea (crea una copia con nuevo ID justo debajo).
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
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }
}