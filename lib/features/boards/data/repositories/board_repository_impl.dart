import 'package:doboard/features/boards/domain/entities/board.dart';
import 'package:doboard/features/boards/domain/repositories/i_board_repository.dart';
import 'package:doboard/shared/database/app_database.dart';
import 'package:doboard/shared/database/mappers.dart';

class BoardRepositoryImpl implements IBoardRepository {
  const BoardRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Stream<List<Board>> watchVisibleBoards() {
    return _db.boardsDao
        .watchVisibleBoards()
        .map((rows) => rows.map((r) => r.toBoard()).toList());
  }

  @override
  Stream<List<Board>> watchAllBoards() {
    return _db.boardsDao
        .watchAllBoards()
        .map((rows) => rows.map((r) => r.toBoard()).toList());
  }

  @override
  Future<void> updateBoard(Board board) {
    return _db.boardsDao.updateBoard(board.toCompanion());
  }

  @override
  Future<void> toggleVisibility(String boardId, {required bool isVisible}) {
    return _db.boardsDao.toggleVisibility(boardId, isVisible: isVisible);
  }

  @override
  Future<void> reorderBoards(List<String> orderedIds) {
    final positions = {
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
    };
    return _db.boardsDao.reorderBoards(positions);
  }
}