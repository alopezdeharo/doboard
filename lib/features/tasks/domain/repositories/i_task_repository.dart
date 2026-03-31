import '../entities/subtask.dart';
import '../entities/task.dart';
import '../entities/priority.dart';

/// Contrato para operaciones CRUD sobre tareas y subtareas.
abstract interface class ITaskRepository {
  // ─── Tareas ────────────────────────────────────────────────────────────────

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
  });

  Future<void> updateTask(Task task);

  Future<void> deleteTask(String id);

  Future<void> toggleDone(String id, {required bool isDone});

  Future<void> moveToBoard(String taskId, String targetBoardId);

  Future<void> setFrog(String taskId, String boardId);
  Future<void> removeFrog(String taskId);

  Future<void> reorderTasks(String boardId, List<String> orderedIds);

  Future<void> clearCompleted(String boardId);

  Future<void> duplicateTask(String taskId);

  // ─── Subtareas ─────────────────────────────────────────────────────────────

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

  /// Convierte una subtarea en tarea principal en el mismo tablero.
  Future<void> promoteSubtaskToTask({
    required String subtaskId,
    required String parentTaskId,
    required String targetBoardId,
  });
}