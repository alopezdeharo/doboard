class Note {
  const Note({
    required this.id,
    required this.taskId,
    required this.contentJson,
    required this.plainText,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String taskId;
  final String contentJson;
  final String plainText;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({
    String? id, String? taskId, String? contentJson,
    String? plainText, DateTime? createdAt, DateTime? updatedAt,
  }) => Note(
    id: id ?? this.id, taskId: taskId ?? this.taskId,
    contentJson: contentJson ?? this.contentJson,
    plainText: plainText ?? this.plainText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Note && id == other.id;

  @override
  int get hashCode => id.hashCode;

  bool get isEmpty => plainText.trim().isEmpty;
  String get preview => plainText.length <= 120
      ? plainText
      : '${plainText.substring(0, 117)}...';
}