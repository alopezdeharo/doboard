import '../entities/subtask.dart';
import '../entities/task.dart';
import '../entities/priority.dart';

abstract interface class ITaskRepository {
  Stream<List<Task>> watchTasksByBoard(String boardId);
  Stream<List<Task>> watchPendingTasksByBoard(String boardId);
  Future<Task?> getTaskById(String id);

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

  /// Cuando se completa una tarea promovida, marca también la subtarea
  /// original en el padre con el mismo estado.
  Future<void> syncPromotedSubtaskDone(String taskId, {required bool isDone});

  /// Programa la tarea para moverse a "Hoy" en la fecha dada.
  Future<void> scheduleTask(String taskId, DateTime date);

  /// Cancela la programación.
  Future<void> cancelSchedule(String taskId);

  /// Mueve a "Hoy" todas las tareas cuya fecha programada ya llegó.
  Future<int> processScheduledTasks(String todayBoardId);

  Stream<List<Subtask>> watchSubtasksByTask(String taskId);
  Future<void> createSubtask({
    required String id,
    required String taskId,
    required String title,
  });
  Future<void> updateSubtask(Subtask subtask);
  Future<void> toggleSubtaskDone(String id, {required bool isDone});
  Future<void> deleteSubtask(String id);
  Future<void> reorderSubtasks(String taskId, List<String> orderedIds);
  Future<void> promoteSubtaskToTask({
    required String subtaskId,
    required String parentTaskId,
    required String targetBoardId,
  });
}