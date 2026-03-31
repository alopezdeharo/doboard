class Subtask {
  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isDone,
    required this.position,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isDone;
  final int position;
  final DateTime createdAt;

  Subtask copyWith({
    String? id, String? taskId, String? title,
    bool? isDone, int? position, DateTime? createdAt,
  }) => Subtask(
    id: id ?? this.id, taskId: taskId ?? this.taskId,
    title: title ?? this.title, isDone: isDone ?? this.isDone,
    position: position ?? this.position, createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Subtask && id == other.id;

  @override
  int get hashCode => id.hashCode;
}