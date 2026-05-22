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
final workBoardsProvider = StreamProvider<List<Board>>((ref) {
  return ref
      .watch(boardRepositoryProvider)
      .watchVisibleBoards()
      .map((boards) => boards.where((b) => b.id != 'board-hoy').toList());
});

/// Índice del tablero de trabajo activo dentro de la pestaña Tareas.
/// Separado del flujo principal (que ahora siempre tiene 3 páginas fijas).
final activeWorkBoardIndexProvider = StateProvider<int>((ref) => 0);

/// Flujo principal siempre tiene exactamente 3 páginas: Hoy · Tareas · Próximo.
final mainFlowPageIndexProvider = StateProvider<int>((ref) => 0);

int mainFlowPageCount(int workBoardCount) => 3;

int clampMainFlowPage(int page, int workBoardCount) => page.clamp(0, 2);

/// Pestaña del [NavigationBar] según la página global (0=Hoy, 1=Tareas, 2=Próximo).
int navBarSelectedIndexForMainFlowPage(int mainFlowPage, int workBoardCount) {
  return mainFlowPage.clamp(0, 2);
}

/// Página global al pulsar una pestaña del navbar.
int mainFlowPageForNavBarTap(
  int navIndex,
  int workBoardCount,
  int currentMainFlowPage,
) {
  return navIndex.clamp(0, 2);
}
