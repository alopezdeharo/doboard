import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/board.dart';

/// Todos los tableros visibles (incluyendo Hoy), ordenados por posición.
final visibleBoardsProvider = StreamProvider<List<Board>>((ref) {
  return ref.watch(boardRepositoryProvider).watchVisibleBoards();
});

/// Todos los tableros (incluyendo ocultos, para Ajustes).
final allBoardsProvider = StreamProvider<List<Board>>((ref) {
  return ref.watch(boardRepositoryProvider).watchAllBoards();
});

/// Solo los tableros de trabajo (excluye 'board-hoy').
/// Alimenta la pestaña Tableros del MainShell.
final workBoardsProvider = StreamProvider<List<Board>>((ref) {
  return ref
      .watch(boardRepositoryProvider)
      .watchVisibleBoards()
      .map((boards) => boards.where((b) => b.id != 'board-hoy').toList());
});

/// Página activa del flujo horizontal único: 0 = Hoy, 1…N = tableros de
/// trabajo en orden, N+1 = Próximo ([mainFlowPageCount] páginas en total).
final mainFlowPageIndexProvider = StateProvider<int>((ref) => 0);

/// Número de páginas: Hoy + tableros de trabajo + Próximo.
int mainFlowPageCount(int workBoardCount) => 1 + workBoardCount + 1;

int clampMainFlowPage(int page, int workBoardCount) {
  final last = mainFlowPageCount(workBoardCount) - 1;
  if (last < 0) return 0;
  return page.clamp(0, last);
}

/// Pestaña del [NavigationBar] (0=Hoy, 1=Tareas, 2=Próximo) según página global.
int navBarSelectedIndexForMainFlowPage(int mainFlowPage, int workBoardCount) {
  if (mainFlowPage <= 0) return 0;
  final proximoPage = workBoardCount + 1;
  if (mainFlowPage >= proximoPage) return 2;
  return 1;
}

/// Página global al pulsar una pestaña del navbar.
int mainFlowPageForNavBarTap(
  int navIndex,
  int workBoardCount,
  int currentMainFlowPage,
) {
  switch (navIndex) {
    case 0:
      return 0;
    case 2:
      return clampMainFlowPage(workBoardCount + 1, workBoardCount);
    case 1:
    default:
      if (workBoardCount == 0) return 0;
      const workStart = 1;
      final workEnd = workBoardCount;
      if (currentMainFlowPage >= workStart &&
          currentMainFlowPage <= workEnd) {
        return currentMainFlowPage;
      }
      return workStart;
  }
}