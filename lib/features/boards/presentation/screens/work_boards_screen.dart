import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/settings/domain/entities/app_settings.dart';
import '../../domain/entities/board.dart';
import '../providers/boards_provider.dart';
import '../widgets/board_page.dart';
import '../widgets/board_nav_dots.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import '../../../tasks/presentation/widgets/quick_input_bar.dart';

/// Shell persistente de la sección Tareas.
///
/// El header, las tabs y la barra de input se quedan fijos.
/// Solo la lista de tareas del centro anima con un slide al cambiar de tab.
class WorkBoardPageScaffold extends ConsumerStatefulWidget {
  const WorkBoardPageScaffold({
    super.key,
    required this.workBoards,
  });

  final List<Board> workBoards;

  @override
  ConsumerState<WorkBoardPageScaffold> createState() =>
      _WorkBoardPageScaffoldState();
}

class _WorkBoardPageScaffoldState
    extends ConsumerState<WorkBoardPageScaffold> {
  late PageController _boardPageController;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(activeWorkBoardIndexProvider);
    _lastIndex = initial;
    _boardPageController = PageController(initialPage: initial);
  }

  @override
  void dispose() {
    _boardPageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _lastIndex) return;

    ref.read(activeWorkBoardIndexProvider.notifier).state = index;

    // Slide directo entre tabs (sin pasar por intermedios)
    _boardPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    _lastIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    final workBoards = widget.workBoards;

    if (workBoards.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const SafeArea(
          child: Center(child: Text('No hay tableros de trabajo')),
        ),
      );
    }

    final activeIndex = ref.watch(activeWorkBoardIndexProvider);
    final safeIndex = activeIndex.clamp(0, workBoards.length - 1);
    final currentBoard = workBoards[safeIndex];

    final settingsAsync = ref.watch(settingsProvider);
    final inputPos =
        settingsAsync.valueOrNull?.inputPosition ?? InputPosition.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header fijo ─────────────────────────────────────────────────
            _WorkBoardsHeader(boardId: currentBoard.id),

            if (inputPos == InputPosition.top)
              QuickInputBar(boardId: currentBoard.id),

            const SizedBox(height: 8),

            // ── Tabs fijas ──────────────────────────────────────────────────
            BoardNavTabs(
              boards: workBoards,
              currentIndex: safeIndex,
              onTabTap: _onTabTap,
            ),

            // ── Listas animadas ─────────────────────────────────────────────
            // PageView interno con NeverScrollableScrollPhysics:
            // - El usuario no puede hacer swipe (el outer PageView ya gestiona Hoy/Próximo)
            // - Los tabs controlan la navegación programáticamente
            // - _KeepAlivePage preserva el scroll de cada lista tras primera visita
            Expanded(
              child: PageView.builder(
                controller: _boardPageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workBoards.length,
                itemBuilder: (context, index) {
                  final board = workBoards[index];
                  return _KeepAlivePage(
                    key: ValueKey(board.id),
                    child: BoardPage(
                      board: board,
                      isActive: index == safeIndex,
                    ),
                  );
                },
              ),
            ),

            if (inputPos == InputPosition.bottom)
              QuickInputBar(boardId: currentBoard.id),
          ],
        ),
      ),
    );
  }
}

// ─── Wrapper KeepAlive ────────────────────────────────────────────────────────
// Impide que el PageView descarte el scroll de páginas no activas.

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({super.key, required this.child});
  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // obligatorio con AutomaticKeepAliveClientMixin
    return widget.child;
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _WorkBoardsHeader extends ConsumerWidget {
  const _WorkBoardsHeader({required this.boardId});
  final String boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tareas',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: theme.colorScheme.onSurface,
              ),
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

// ─── Botón limpiar ────────────────────────────────────────────────────────────

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

// ─── Confirmación limpiar ─────────────────────────────────────────────────────

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
