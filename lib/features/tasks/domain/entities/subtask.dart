class Subtask {
  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isDone,
    required this.position,
    required this.createdAt,
    this.isPromoted = false,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isDone;
  final int position;
  final DateTime createdAt;
  /// True si esta subtarea fue promovida a tarea en otra columna.
  /// Se muestra visualmente como "fantasma" en la lista del padre.
  final bool isPromoted;

  Subtask copyWith({
    String? id, String? taskId, String? title,
    bool? isDone, int? position, DateTime? createdAt, bool? isPromoted,
  }) => Subtask(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    title: title ?? this.title,
    isDone: isDone ?? this.isDone,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    isPromoted: isPromoted ?? this.isPromoted,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Subtask && id == other.id;
  @override
  int get hashCode => id.hashCode;
}