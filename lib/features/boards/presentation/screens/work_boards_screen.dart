import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/settings/domain/entities/app_settings.dart';
import '../../domain/entities/board.dart';
import '../widgets/board_page.dart';
import '../widgets/board_nav_dots.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import '../../../tasks/presentation/widgets/quick_input_bar.dart';

/// Una página del flujo principal: un tablero de trabajo (cabecera, dots,
/// lista). El deslizamiento entre tableros lo gestiona [MainShell].
class WorkBoardPageScaffold extends ConsumerWidget {
  const WorkBoardPageScaffold({
    super.key,
    required this.workBoards,
    required this.workBoardIndex,
    required this.onJumpToWorkBoardIndex,
  });

  final List<Board> workBoards;
  final int workBoardIndex;
  final ValueChanged<int> onJumpToWorkBoardIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (workBoards.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const SafeArea(
          child: Center(child: Text('No hay tableros de trabajo')),
        ),
      );
    }

    final safeIndex = workBoardIndex.clamp(0, workBoards.length - 1);
    final currentBoard = workBoards[safeIndex];
    final settingsAsync = ref.watch(settingsProvider);
    final inputPos =
        settingsAsync.valueOrNull?.inputPosition ?? InputPosition.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _WorkBoardsHeader(
              boards: workBoards,
              currentIndex: safeIndex,
            ),
            if (inputPos == InputPosition.top)
              QuickInputBar(boardId: currentBoard.id),
            BoardNavDots(
              count: workBoards.length,
              currentIndex: safeIndex,
              onDotTap: onJumpToWorkBoardIndex,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: BoardPage(board: currentBoard, isActive: true),
            ),
            if (inputPos == InputPosition.bottom)
              QuickInputBar(boardId: currentBoard.id),
          ],
        ),
      ),
    );
  }
}

// ─── Header de la pestaña Tableros ────────────────────────────────────────────

class _WorkBoardsHeader extends ConsumerWidget {
  const _WorkBoardsHeader({
    required this.boards,
    required this.currentIndex,
  });

  final List<Board> boards;
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = boards[currentIndex];
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
      child: Row(
        children: [
          Text(board.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Column(
                key: ValueKey(board.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    board.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    board.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _ClearCompletedButton(boardId: board.id),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 22),
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            onPressed: () => context.push('/settings'),
            tooltip: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _ClearCompletedButton extends ConsumerWidget {
  const _ClearCompletedButton({required this.boardId});
  final String boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: () async {
        final confirmed = await showModalBottomSheet<bool>(
              context: context,
              builder: (_) => const _ClearConfirmSheet(),
            ) ??
            false;
        if (confirmed) {
          ref.read(taskActionsProvider.notifier).clearCompleted(boardId);
        }
      },
      icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
      label: const Text('Limpiar'),
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface.withOpacity(0.45),
        textStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ClearConfirmSheet extends StatelessWidget {
  const _ClearConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('¿Limpiar tareas completadas?',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Se eliminarán permanentemente de este tablero.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Limpiar'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
