import 'package:doboard/core/utils/automation_engine.dart';
import 'package:doboard/features/tasks/domain/entities/priority.dart';
import 'package:doboard/features/tasks/domain/entities/subtask.dart';
import 'package:doboard/features/tasks/domain/entities/task.dart';
import 'package:doboard/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:doboard/shared/database/app_database.dart';
import 'package:doboard/shared/database/mappers.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class TaskRepositoryImpl implements ITaskRepository {
  const TaskRepositoryImpl(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  // ─── Tareas ────────────────────────────────────────────────────────────────

  @override
  Stream<List<Task>> watchTasksByBoard(String boardId) {
    return _db.tasksDao
        .watchTasksByBoard(boardId)
        .map((rows) => rows.map((r) => r.toTask()).toList());
  }

  @override
  Stream<List<Task>> watchPendingTasksByBoard(String boardId) {
    return _db.tasksDao
        .watchPendingTasksByBoard(boardId)
        .map((rows) => rows.map((r) => r.toTask()).toList());
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final data = await _db.tasksDao.getTaskById(id);
    return data?.toTask();
  }

  @override
  Future<void> createTask({
    required String id,
    required String boardId,
    required String title,
    String? content,
    Priority priority = Priority.low,
    String? detectedKeyword,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.tasksDao.insertTask(TasksCompanion(
      id: Value(id),
      boardId: Value(boardId),
      title: Value(title),
      content: Value(content),
      priority: Value(priority.value),
      position: const Value(0),
      isDone: const Value(false),
      isFrog: const Value(false),
      isPinned: const Value(false),
      detectedKeyword: Value(detectedKeyword),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  @override
  Future<void> updateTask(Task task) {
    return _db.tasksDao.updateTask(task.toCompanion());
  }

  @override
  Future<void> deleteTask(String id) {
    return _db.tasksDao.deleteTask(id);
  }

  @override
  Future<void> toggleDone(String id, {required bool isDone}) {
    return _db.tasksDao.toggleDone(id, isDone: isDone);
  }

  @override
  Future<void> moveToBoard(String taskId, String targetBoardId) {
    return _db.tasksDao.moveToBoard(taskId, targetBoardId);
  }

  @override
  Future<void> setFrog(String taskId, String boardId) {
    return _db.tasksDao.setFrog(taskId, boardId);
  }

  @override
  Future<void> removeFrog(String taskId) {
    return _db.tasksDao.removeFrog(taskId);
  }

  @override
  Future<void> reorderTasks(String boardId, List<String> orderedIds) {
    final positions = {
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
    };
    return _db.tasksDao.reorderTasks(positions);
  }

  @override
  Future<void> clearCompleted(String boardId) {
    return _db.tasksDao.clearCompleted(boardId);
  }

  @override
  Future<void> duplicateTask(String taskId) async {
    final data = await _db.tasksDao.getTaskById(taskId);
    if (data == null) return;
    return _db.tasksDao.duplicateTask(data, _uuid.v4());
  }

  // ─── Subtareas ─────────────────────────────────────────────────────────────

  @override
  Stream<List<Subtask>> watchSubtasksByTask(String taskId) {
    return _db.subtasksDao
        .watchSubtasksByTask(taskId)
        .map((rows) => rows.map((r) => r.toSubtask()).toList());
  }

  @override
  Future<void> createSubtask({
    required String id,
    required String taskId,
    required String title,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.subtasksDao.insertSubtask(SubtasksCompanion(
      id: Value(id),
      taskId: Value(taskId),
      title: Value(title),
      isDone: const Value(false),
      position: const Value(0),
      createdAt: Value(now),
    ));
  }

  @override
  Future<void> updateSubtask(Subtask subtask) {
    return _db.subtasksDao.updateSubtask(subtask.toCompanion());
  }

  @override
  Future<void> toggleSubtaskDone(String id, {required bool isDone}) {
    return _db.subtasksDao.toggleDone(id, isDone: isDone);
  }

  @override
  Future<void> deleteSubtask(String id) {
    return _db.subtasksDao.deleteSubtask(id);
  }

  @override
  Future<void> reorderSubtasks(String taskId, List<String> orderedIds) {
    final positions = {
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
    };
    return _db.subtasksDao.reorderSubtasks(positions);
  }

  @override
  Future<void> promoteSubtaskToTask({
    required String subtaskId,
    required String parentTaskId,
    required String targetBoardId,
  }) async {
    final subtasks = await _db.subtasksDao.getSubtasksByTask(parentTaskId);
    final subtask = subtasks.where((s) => s.id == subtaskId).firstOrNull;
    if (subtask == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      // Eliminar la subtarea
      await _db.subtasksDao.deleteSubtask(subtaskId);
      // Crear una tarea nueva con el mismo título
      await _db.tasksDao.insertTask(TasksCompanion(
        id: Value(_uuid.v4()),
        boardId: Value(targetBoardId),
        title: Value(subtask.title),
        priority: const Value(0),
        position: const Value(0),
        isDone: const Value(false),
        isFrog: const Value(false),
        isPinned: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
    });
  }
}