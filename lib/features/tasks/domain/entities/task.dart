import 'priority.dart';
import 'subtask.dart';

class Task {
  const Task({
    required this.id,
    required this.boardId,
    required this.title,
    this.content,
    required this.priority,
    required this.position,
    required this.isDone,
    required this.isFrog,
    required this.isPinned,
    this.detectedKeyword,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.subtasks = const [],
    this.hasNote = false,
    // Referencia al padre si esta tarea fue una subtarea promovida
    this.parentTaskTitle,
  });

  final String id;
  final String boardId;
  final String title;
  final String? content;
  final Priority priority;
  final int position;
  final bool isDone;
  final bool isFrog;
  final bool isPinned;
  final String? detectedKeyword;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final List<Subtask> subtasks;
  final bool hasNote;
  /// Título de la tarea padre si esta fue promovida desde subtarea.
  /// Se muestra como "↳ Nombre de tarea" en la tarjeta.
  final String? parentTaskTitle;

  Task copyWith({
    String? id, String? boardId, String? title, String? content,
    Priority? priority, int? position, bool? isDone, bool? isFrog,
    bool? isPinned, String? detectedKeyword, DateTime? createdAt,
    DateTime? updatedAt, DateTime? completedAt,
    List<Subtask>? subtasks, bool? hasNote, String? parentTaskTitle,
    bool clearParent = false,
  }) => Task(
    id: id ?? this.id,
    boardId: boardId ?? this.boardId,
    title: title ?? this.title,
    content: content ?? this.content,
    priority: priority ?? this.priority,
    position: position ?? this.position,
    isDone: isDone ?? this.isDone,
    isFrog: isFrog ?? this.isFrog,
    isPinned: isPinned ?? this.isPinned,
    detectedKeyword: detectedKeyword ?? this.detectedKeyword,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt ?? this.completedAt,
    subtasks: subtasks ?? this.subtasks,
    hasNote: hasNote ?? this.hasNote,
    parentTaskTitle: clearParent ? null : (parentTaskTitle ?? this.parentTaskTitle),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Task && id == other.id;
  @override
  int get hashCode => id.hashCode;

  bool get hasSubtasks => subtasks.isNotEmpty;
  bool get isPromotedSubtask => parentTaskTitle != null;
  int get completedSubtasks => subtasks.where((s) => s.isDone).length;
  String get subtaskProgress =>
      subtasks.isEmpty ? '' : '$completedSubtasks/${subtasks.length}';
  bool get isUrgent => priority == Priority.high;
}