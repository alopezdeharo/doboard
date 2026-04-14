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

/// Índice activo dentro de la pestaña Tableros (0 = Rápidas…).
final workBoardIndexProvider = StateProvider<int>((ref) => 0);

/// Índice de la pestaña activa en el MainShell (0=Hoy, 1=Tableros, 2=Próximo).
final shellIndexProvider = StateProvider<int>((ref) => 0);