import '../entities/board.dart';

/// Contrato que debe implementar cualquier fuente de datos para tableros.
/// La capa Presentation solo conoce esta interfaz — nunca la implementación.
abstract interface class IBoardRepository {
  /// Stream reactivo de todos los tableros visibles, ordenados por posición.
  Stream<List<Board>> watchVisibleBoards();

  /// Stream de todos los tableros (incluyendo ocultos, para Ajustes).
  Stream<List<Board>> watchAllBoards();

  /// Actualiza nombre, subtítulo, color u otras propiedades de un tablero.
  Future<void> updateBoard(Board board);

  /// Cambia la visibilidad de un tablero (mostrar/ocultar en la UI).
  Future<void> toggleVisibility(String boardId, {required bool isVisible});

  /// Reordena los tableros tras un drag & drop en Ajustes.
  /// [orderedIds] es la lista de IDs en el nuevo orden.
  Future<void> reorderBoards(List<String> orderedIds);
}