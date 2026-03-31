import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/boards_table.dart';

part 'boards_dao.g.dart';

@DriftAccessor(tables: [Boards])
class BoardsDao extends DatabaseAccessor<AppDatabase> with _$BoardsDaoMixin {
  BoardsDao(super.db);

  // ─── Lecturas ──────────────────────────────────────────────────────────────

  /// Stream de todos los tableros ordenados por posición.
  /// Se emite automáticamente cuando hay cambios en la tabla.
  Stream<List<BoardData>> watchAllBoards() {
    return (select(boards)..orderBy([(b) => OrderingTerm.asc(b.position)]))
        .watch();
  }

  /// Stream solo de tableros visibles (para la UI principal).
  Stream<List<BoardData>> watchVisibleBoards() {
    return (select(boards)
      ..where((b) => b.isVisible.equals(true))
      ..orderBy([(b) => OrderingTerm.asc(b.position)]))
        .watch();
  }

  /// Obtiene un tablero por ID (lectura única, sin stream).
  Future<BoardData?> getBoardById(String id) {
    return (select(boards)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  // ─── Escrituras ────────────────────────────────────────────────────────────

  /// Inserta un nuevo tablero.
  Future<void> insertBoard(BoardsCompanion board) {
    return into(boards).insert(board);
  }

  /// Actualiza un tablero existente.
  Future<bool> updateBoard(BoardsCompanion board) {
    return update(boards).replace(board);
  }

  /// Cambia la visibilidad de un tablero.
  Future<void> toggleVisibility(String boardId, {required bool isVisible}) {
    return (update(boards)..where((b) => b.id.equals(boardId))).write(
      BoardsCompanion(isVisible: Value(isVisible)),
    );
  }

  /// Actualiza las posiciones de varios tableros en una sola transacción.
  /// [positions] es un mapa de {boardId: newPosition}.
  Future<void> reorderBoards(Map<String, int> positions) async {
    await transaction(() async {
      for (final entry in positions.entries) {
        await (update(boards)..where((b) => b.id.equals(entry.key))).write(
          BoardsCompanion(position: Value(entry.value)),
        );
      }
    });
  }

  // ─── Seed data ─────────────────────────────────────────────────────────────

  /// Inserta los 4 tableros por defecto si la tabla está vacía.
  /// Se llama en la migración inicial de AppDatabase.
  Future<void> seedDefaultBoards() async {
    final existing = await select(boards).get();
    if (existing.isNotEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    const defaults = [
      (
      id: 'board-hoy',
      name: 'Hoy',
      subtitle: 'Come la rana primero 🐸',
      emoji: '🐸',
      color: '#1D9E75',
      pos: 0,
      ),
      (
      id: 'board-rapidas',
      name: 'Rápidas',
      subtitle: 'Menos de 10 minutos',
      emoji: '⚡',
      color: '#185FA5',
      pos: 1,
      ),
      (
      id: 'board-calma',
      name: 'Con calma',
      subtitle: '30 a 60 minutos',
      emoji: '🧘',
      color: '#BA7517',
      pos: 2,
      ),
      (
      id: 'board-prisa',
      name: 'Sin prisa',
      subtitle: 'Más de una hora',
      emoji: '🌿',
      color: '#533AB7', // c-purple 600
      pos: 3,
      ),
    ];

    await transaction(() async {
      for (final d in defaults) {
        await into(boards).insert(BoardsCompanion(
          id: Value(d.id),
          name: Value(d.name),
          subtitle: Value(d.subtitle),
          emoji: Value(d.emoji),
          colorHex: Value(d.color),
          position: Value(d.pos),
          isVisible: const Value(true),
          createdAt: Value(now),
        ));
      }
    });
  }
}