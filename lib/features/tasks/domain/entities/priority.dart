/// Prioridad de una tarea.
/// Se persiste en SQLite como int (0/1/2) para simplicidad.
enum Priority {
  low(0),
  medium(1),
  high(2);

  const Priority(this.value);
  final int value;

  static Priority fromValue(int value) {
    return Priority.values.firstWhere(
          (p) => p.value == value,
      orElse: () => Priority.low,
    );
  }

  /// Color hex del indicador lateral de la tarjeta.
  String get colorHex {
    switch (this) {
      case Priority.high:
        return '#E24B4A'; // c-red 400
      case Priority.medium:
        return '#EF9F27'; // c-amber 400
      case Priority.low:
        return 'transparent';
    }
  }
}