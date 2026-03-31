import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/automation_engine.dart';
import '../../domain/entities/subtask.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/i_task_repository.dart';

// ─── Stream providers ─────────────────────────────────────────────────────────

final tasksByBoardProvider =
StreamProvider.family<List<Task>, String>((ref, boardId) {
  return ref.watch(taskRepositoryProvider).watchTasksByBoard(boardId);
});

final subtasksByTaskProvider =
StreamProvider.family<List<Subtask>, String>((ref, taskId) {
  return ref.watch(taskRepositoryProvider).watchSubtasksByTask(taskId);
});

// ─── Drag & drop ──────────────────────────────────────────────────────────────

/// La tarea que se está arrastrando actualmente (null = ninguna).
final dragStateProvider = StateProvider<Task?>((ref) => null);

// ─── Acciones sobre tareas ────────────────────────────────────────────────────

class TaskActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  ITaskRepository get _repo => ref.read(taskRepositoryProvider);

  Future<void> createTask({
    required String boardId,
    required String title,
    String? content,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final keyword = AutomationEngine.instance.detect(title);
      await _repo.createTask(
        id: const Uuid().v4(),
        boardId: boardId,
        title: title.trim(),
        content: content,
        detectedKeyword: keyword,
      );
    });
  }

  Future<void> updateTask(Task task) => _repo.updateTask(task);

  Future<void> toggleDone(String taskId, {required bool isDone}) =>
      _repo.toggleDone(taskId, isDone: isDone);

  Future<void> deleteTask(String taskId) => _repo.deleteTask(taskId);

  Future<void> moveToBoard(String taskId, String targetBoardId) =>
      _repo.moveToBoard(taskId, targetBoardId);

  Future<void> reorderTasks(String boardId, List<String> orderedIds) =>
      _repo.reorderTasks(boardId, orderedIds);

  Future<void> setFrog(String taskId, String boardId) =>
      _repo.setFrog(taskId, boardId);

  Future<void> removeFrog(String taskId) => _repo.removeFrog(taskId);

  Future<void> clearCompleted(String boardId) => _repo.clearCompleted(boardId);

  Future<void> duplicateTask(String taskId) => _repo.duplicateTask(taskId);

  Future<void> createSubtask({required String taskId, required String title}) =>
      _repo.createSubtask(id: const Uuid().v4(), taskId: taskId, title: title.trim());

  Future<void> toggleSubtaskDone(String subtaskId, {required bool isDone}) =>
      _repo.toggleSubtaskDone(subtaskId, isDone: isDone);

  Future<void> deleteSubtask(String subtaskId) => _repo.deleteSubtask(subtaskId);

  Future<void> promoteSubtask({
    required String subtaskId,
    required String parentTaskId,
    required String targetBoardId,
  }) => _repo.promoteSubtaskToTask(
    subtaskId: subtaskId,
    parentTaskId: parentTaskId,
    targetBoardId: targetBoardId,
  );
}

final taskActionsProvider =
NotifierProvider<TaskActionsNotifier, AsyncValue<void>>(
    TaskActionsNotifier.new);