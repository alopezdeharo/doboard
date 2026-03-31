class Board {
  const Board({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.colorHex,
    required this.emoji,
    required this.position,
    required this.isVisible,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String subtitle;
  final String colorHex;
  final String emoji;
  final int position;
  final bool isVisible;
  final DateTime createdAt;

  Board copyWith({
    String? id, String? name, String? subtitle, String? colorHex,
    String? emoji, int? position, bool? isVisible, DateTime? createdAt,
  }) => Board(
    id: id ?? this.id, name: name ?? this.name,
    subtitle: subtitle ?? this.subtitle, colorHex: colorHex ?? this.colorHex,
    emoji: emoji ?? this.emoji, position: position ?? this.position,
    isVisible: isVisible ?? this.isVisible, createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Board && id == other.id;

  @override
  int get hashCode => id.hashCode;
}