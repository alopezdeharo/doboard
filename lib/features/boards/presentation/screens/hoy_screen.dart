import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/settings/domain/entities/app_settings.dart';
import '../providers/boards_provider.dart';
import '../widgets/board_page.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import '../../../tasks/presentation/providers/frog_provider.dart';
import '../../../tasks/presentation/widgets/quick_input_bar.dart';

/// Pestaña "Hoy" del MainShell.
/// Muestra únicamente el tablero 'board-hoy' con su input rápido.
class HoyScreen extends ConsumerWidget {
  const HoyScreen({super.key});

  static const _boardId = 'board-hoy';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync  = ref.watch(visibleBoardsProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final inputPos     = settingsAsync.valueOrNull?.inputPosition
        ?? InputPosition.bottom;
    final frogEnabled  = settingsAsync.valueOrNull?.frogEnabled ?? false;

    return boardsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (boards) {
        final board = boards.firstWhere(
          (b) => b.id == _boardId,
          orElse: () => boards.first,
        );

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                _HoyHeader(boardId: board.id, frogEnabled: frogEnabled),
                if (inputPos == InputPosition.top)
                  QuickInputBar(boardId: board.id),
                // Banner rana fuera de Hoy (solo si ETF activo)
                if (frogEnabled)
                  _FrogBanner(currentBoardId: board.id),
                Expanded(
                  child: BoardPage(board: board, isActive: true),
                ),
                if (inputPos == InputPosition.bottom)
                  QuickInputBar(boardId: board.id),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Header de Hoy ────────────────────────────────────────────────────────────

class _HoyHeader extends ConsumerWidget {
  const _HoyHeader({required this.boardId, required this.frogEnabled});
  final String boardId;
  final bool frogEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
      child: Row(
        children: [
          // El emoji de rana solo aparece si ETF está activo
          if (frogEnabled) ...[
            const Text('🐸', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoy',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (frogEnabled)
                  Text(
                    'Come la rana primero',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
          _ClearCompletedButton(boardId: boardId),
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

// ─── Banner rana fuera de Hoy ─────────────────────────────────────────────────

class _FrogBanner extends ConsumerWidget {
  const _FrogBanner({required this.currentBoardId});
  final String currentBoardId;

  static const _boardNames = {
    'board-rapidas': 'Tareas rápidas',
    'board-calma':   'Tareas medias',
    'board-prisa':   'Tareas largas',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frogAsync = ref.watch(frogTaskProvider);
    final theme = Theme.of(context);

    return frogAsync.maybeWhen(
      data: (frog) {
        // No mostrar si no hay rana, o si ya está en Hoy
        if (frog == null || frog.boardId == currentBoardId) {
          return const SizedBox.shrink();
        }

        final boardName = _boardNames[frog.boardId] ?? 'otro tablero';

        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4DB87A).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4DB87A).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(children: [
              const Text('🐸', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu rana está en $boardName',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF4DB87A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '"${frog.title}"',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Botón "Añadir a Hoy"
              GestureDetector(
                onTap: () {
                  ref
                      .read(taskActionsProvider.notifier)
                      .moveToBoard(frog.id, currentBoardId);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4DB87A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Añadir a Hoy',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF4DB87A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ─── Botón limpiar completadas ────────────────────────────────────────────────

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
              useSafeArea: true,
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset > 0 ? bottomInset + 16 : 32),
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
