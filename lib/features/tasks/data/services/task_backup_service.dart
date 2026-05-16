import 'dart:convert';

import 'package:doboard/core/services/notification_service.dart';
import 'package:doboard/shared/database/app_database.dart';

/// Formato del archivo JSON de respaldo de tareas (sin ajustes de la app).
const taskBackupFormatId = 'doboard_tasks';
const taskBackupFormatVersion = 1;

class TaskBackupException implements Exception {
  TaskBackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Exporta e importa tareas, subtareas y notas asociadas en la base local.
class TaskBackupService {
  TaskBackupService(this._db);

  final AppDatabase _db;

  Future<String> exportToJsonString() async {
    final tasks = await _db.select(_db.tasks).get();
    final subtasks = await _db.select(_db.subtasks).get();
    final notes = await _db.select(_db.notes).get();

    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'format': taskBackupFormatId,
      'version': taskBackupFormatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tasks': tasks.map((e) => e.toJson()).toList(),
      'subtasks': subtasks.map((e) => e.toJson()).toList(),
      'notes': notes.map((e) => e.toJson()).toList(),
    });
  }

  /// Sustituye todas las tareas, subtareas y notas por el contenido del backup.
  /// No modifica tableros ni ajustes. Reprograma notificaciones de tareas con fecha.
  Future<void> importFromJsonString(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw TaskBackupException('El archivo no es un objeto JSON válido.');
    }
    final root = Map<String, dynamic>.from(decoded);

    if (root['format'] != taskBackupFormatId) {
      throw TaskBackupException(
        'No es un archivo de respaldo de Doboard (formato desconocido).',
      );
    }
    final version = root['version'];
    if (version is! int || version != taskBackupFormatVersion) {
      throw TaskBackupException(
        'Versión de archivo no soportada (se esperaba $taskBackupFormatVersion).',
      );
    }

    final tasksJson = root['tasks'];
    final subtasksJson = root['subtasks'];
    final notesJson = root['notes'];
    if (tasksJson is! List || subtasksJson is! List || notesJson is! List) {
      throw TaskBackupException('Faltan las listas tasks, subtasks o notes.');
    }

    final boardRows = await _db.select(_db.boards).get();
    final validBoardIds = boardRows.map((b) => b.id).toSet();

    final tasks = <TaskData>[];
    for (final item in tasksJson) {
      if (item is! Map<String, dynamic>) {
        throw TaskBackupException('Entrada inválida en tasks.');
      }
      final task = TaskData.fromJson(item);
      if (!validBoardIds.contains(task.boardId)) {
        throw TaskBackupException(
          'La tarea "${task.title}" referencia un tablero inexistente: ${task.boardId}.',
        );
      }
      tasks.add(task);
    }
    final taskIds = tasks.map((t) => t.id).toSet();
    if (taskIds.length != tasks.length) {
      throw TaskBackupException('Hay identificadores de tarea duplicados.');
    }

    final subtasks = <SubtaskData>[];
    for (final item in subtasksJson) {
      if (item is! Map<String, dynamic>) {
        throw TaskBackupException('Entrada inválida en subtasks.');
      }
      final s = SubtaskData.fromJson(item);
      if (!taskIds.contains(s.taskId)) {
        throw TaskBackupException(
          'Subtarea "${s.title}" referencia una tarea que no está en el backup.',
        );
      }
      subtasks.add(s);
    }
    final subtaskIds = subtasks.map((s) => s.id).toSet();
    if (subtaskIds.length != subtasks.length) {
      throw TaskBackupException('Hay identificadores de subtarea duplicados.');
    }

    final notes = <NoteData>[];
    final seenNoteTaskIds = <String>{};
    for (final item in notesJson) {
      if (item is! Map<String, dynamic>) {
        throw TaskBackupException('Entrada inválida en notes.');
      }
      final n = NoteData.fromJson(item);
      if (!taskIds.contains(n.taskId)) {
        throw TaskBackupException(
          'La nota referencia una tarea que no está en el backup.',
        );
      }
      if (!seenNoteTaskIds.add(n.taskId)) {
        throw TaskBackupException(
          'Hay más de una nota para la misma tarea (${n.taskId}).',
        );
      }
      notes.add(n);
    }
    final noteIds = notes.map((n) => n.id).toSet();
    if (noteIds.length != notes.length) {
      throw TaskBackupException('Hay identificadores de nota duplicados.');
    }

    final existing = await _db.select(_db.tasks).get();
    for (final t in existing) {
      if (t.scheduledDate != null) {
        await NotificationService.instance.cancelTaskNotification(t.id);
      }
    }

    await _db.transaction(() async {
      await _db.delete(_db.subtasks).go();
      await _db.delete(_db.notes).go();
      await _db.delete(_db.tasks).go();

      for (final t in tasks) {
        await _db.into(_db.tasks).insert(t);
      }
      for (final s in subtasks) {
        await _db.into(_db.subtasks).insert(s);
      }
      for (final n in notes) {
        await _db.into(_db.notes).insert(n);
      }
    });

    for (final t in tasks) {
      if (t.scheduledDate != null && !t.isDone) {
        final ms = t.scheduledDate!;
        final day = DateTime.fromMillisecondsSinceEpoch(ms);
        final normalized = DateTime(day.year, day.month, day.day);
        try {
          await NotificationService.instance.scheduleTaskNotification(
            taskId: t.id,
            taskTitle: t.title,
            scheduledDate: normalized,
          );
        } catch (_) {}
      }
    }
  }
}
