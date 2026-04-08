import 'package:doboard/features/tasks/domain/entities/priority.dart';
import 'package:doboard/features/tasks/domain/entities/subtask.dart';
import 'package:doboard/features/tasks/domain/entities/task.dart';
import 'package:doboard/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:doboard/shared/database/app_database.dart';
import 'package:doboard/shared/database/mappers.dart';
import 'package:doboard/core/services/notification_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class TaskRepositoryImpl implements ITaskRepository {
  const TaskRepositoryImpl(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Stream<List<Task>> watchTasksByBoard(String boardId) => _db.tasksDao
      .watchTasksByBoard(boardId)
      .map((rows) => rows.map((r) => r.toTask()).toList());

  @override
  Stream<List<Task>> watchPendingTasksByBoard(String boardId) => _db.tasksDao
      .watchPendingTasksByBoard(boardId)
      .map((rows) => rows.map((r) => r.toTask()).toList());

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
    String? parentTaskTitle,
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
      parentTaskTitle: Value(parentTaskTitle),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  @override
  Future<void> updateTask(Task task) =>
      _db.tasksDao.updateTask(task.toCompanion());

  @override
  Future<void> deleteTask(String id) => _db.tasksDao.deleteTask(id);

  @override
  Future<void> toggleDone(String id, {required bool isDone}) =>
      _db.tasksDao.toggleDone(id, isDone: isDone);

  @override
  Future<void> syncPromotedSubtaskDone(String taskId,
      {required bool isDone}) async {
    final task = await _db.tasksDao.getTaskById(taskId);
    if (task == null || task.parentTaskTitle == null) return;

    final parents = await (_db.select(_db.tasks)
      ..where((t) => t.title.equals(task.parentTaskTitle!)))
        .get();
    if (parents.isEmpty) return;

    for (final parent in parents) {
      final subs = await (_db.select(_db.subtasks)
        ..where((s) =>
        s.taskId.equals(parent.id) &
        s.title.equals(task.title) &
        s.isPromoted.equals(true)))
          .get();
      for (final sub in subs) {
        await (_db.update(_db.subtasks)..where((s) => s.id.equals(sub.id)))
            .write(SubtasksCompanion(isDone: Value(isDone)));
      }
    }
  }

  @override
  Future<void> moveToBoard(String taskId, String targetBoardId) =>
      _db.tasksDao.moveToBoard(taskId, targetBoardId);

  @override
  Future<void> setFrog(String taskId, String boardId) =>
      _db.tasksDao.setFrog(taskId, boardId);

  @override
  Future<void> removeFrog(String taskId) => _db.tasksDao.removeFrog(taskId);

  @override
  Future<void> reorderTasks(String boardId, List<String> orderedIds) {
    final positions = {
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i
    };
    return _db.tasksDao.reorderTasks(positions);
  }

  @override
  Future<void> clearCompleted(String boardId) =>
      _db.tasksDao.clearCompleted(boardId);

  @override
  Future<int> countPendingByBoard(String boardId) =>
      _db.tasksDao.countPendingByBoard(boardId);

  @override
  Future<void> duplicateTask(String taskId) async {
    final data = await _db.tasksDao.getTaskById(taskId);
    if (data == null) return;
    return _db.tasksDao.duplicateTask(data, _uuid.v4());
  }

  @override
  Future<void> scheduleTask(String taskId, DateTime date) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        scheduledDate: Value(date.millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    // Obtener título para el texto de la notificación
    final task = await _db.tasksDao.getTaskById(taskId);
    if (task != null) {
      await NotificationService.instance.scheduleTaskNotification(
        taskId: taskId,
        taskTitle: task.title,
        scheduledDate: date,
      );
    }
  }

  @override
  Future<void> cancelSchedule(String taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      const TasksCompanion(scheduledDate: Value(null)),
    );
    await NotificationService.instance.cancelTaskNotification(taskId);
  }

  @override
  Future<int> processScheduledTasks(String todayBoardId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final count = await _db.tasksDao.moveScheduledTasksToToday(todayBoardId, now);
    // Notificación inmediata de resumen (fallback si el usuario no vio
    // la notificación programada por OS)
    if (count > 0) {
      await NotificationService.instance.showTasksMovedNotification(count);
    }
    return count;
  }

  // ─── Subtareas ─────────────────────────────────────────────────────────────

  @override
  Stream<List<Subtask>> watchSubtasksByTask(String taskId) => _db.subtasksDao
      .watchSubtasksByTask(taskId)
      .map((rows) => rows.map((r) => r.toSubtask()).toList());

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
      isPromoted: const Value(false),
      createdAt: Value(now),
    ));
  }

  @override
  Future<void> updateSubtask(Subtask subtask) =>
      _db.subtasksDao.updateSubtask(subtask.toCompanion());

  @override
  Future<void> toggleSubtaskDone(String id, {required bool isDone}) =>
      _db.subtasksDao.toggleDone(id, isDone: isDone);

  @override
  Future<void> deleteSubtask(String id) => _db.subtasksDao.deleteSubtask(id);

  @override
  Future<void> reorderSubtasks(String taskId, List<String> orderedIds) {
    final positions = {
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i
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

    final parentData = await _db.tasksDao.getTaskById(parentTaskId);
    final parentTitle = parentData?.title;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await ((_db.update(_db.subtasks))
        ..where((s) => s.id.equals(subtaskId)))
          .write(const SubtasksCompanion(isPromoted: Value(true)));

      await _db.tasksDao.insertTask(TasksCompanion(
        id: Value(_uuid.v4()),
        boardId: Value(targetBoardId),
        title: Value(subtask.title),
        priority: const Value(0),
        position: const Value(0),
        isDone: const Value(false),
        isFrog: const Value(false),
        isPinned: const Value(false),
        parentTaskTitle: Value(parentTitle),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
    });
  }
}