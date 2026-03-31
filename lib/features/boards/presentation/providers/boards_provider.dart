import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/board.dart';

final visibleBoardsProvider = StreamProvider<List<Board>>((ref) {
  return ref.watch(boardRepositoryProvider).watchVisibleBoards();
});

final allBoardsProvider = StreamProvider<List<Board>>((ref) {
  return ref.watch(boardRepositoryProvider).watchAllBoards();
});

/// Índice del tablero activo en el PageView.
final currentBoardIndexProvider = StateProvider<int>((ref) => 0);