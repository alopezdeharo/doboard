import '../entities/subtask.dart';
import '../entities/task.dart';
import '../entities/priority.dart';

abstract interface class ITaskRepository {
  Stream<List<Task>> watchTasksByBoard(String boardId);
  Stream<List<Task>> watchPendingTasksByBoard(String boardId);
  Stream<Task?> watchTaskById(String id);
  Future<Task?> getTaskById(String id);

  Stream<List<Task>> watchScheduledTasks();

  Future<void> createTask({
    required String id,
    required String boardId,
    required String title,
    String? content,
    Priority priority,
    String? detectedKeyword,
    String? parentTaskTitle,
  });

  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> toggleDone(String id, {required bool isDone});

  Future<void> moveToBoard(String taskId, String targetBoardId);

  Future<void> setFrog(String taskId, String boardId);
  Future<void> removeFrog(String taskId);
  Future<void> reorderTasks(String boardId, List<String> orderedIds);
  Future<void> clearCompleted(String boardId);
  Future<int> countPendingByBoard(String boardId);
  Future<void> duplicateTask(String taskId);

  Future<void> syncPromotedSubtaskDone(String taskId, {required bool isDone});
  Future<void> scheduleTask(String taskId, DateTime date);
  Future<void> cancelSchedule(String taskId);
  Future<int> processScheduledTasks(String todayBoardId);

  Stream<List<Subtask>> watchSubtasksByTask(String taskId);
  Future<void> createSubtask({
    required String id,
    required String taskId,
    required String title,
  });
  Future<void> updateSubtask(Subtask subtask);

  /// UPDATE parcial: solo actualiza el título, preserva isDone/position/etc.
  Future<void> updateSubtaskTitle(String subtaskId, String newTitle);

  Future<void> toggleSubtaskDone(String id, {required bool isDone});
  Future<void> deleteSubtask(String id);
  Future<void> reorderSubtasks(String taskId, List<String> orderedIds);
  Future<void> promoteSubtaskToTask({
    required String subtaskId,
    required String parentTaskId,
    required String targetBoardId,
  });
}
