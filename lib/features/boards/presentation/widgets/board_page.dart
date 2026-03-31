import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/board.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import '../../../tasks/presentation/widgets/task_card.dart';
import '../../../tasks/presentation/widgets/task_card_draggable.dart';

class BoardPage extends ConsumerWidget {
  const BoardPage({
    super.key,
    required this.board,
    required this.isActive,
  });

  final Board board;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksByBoardProvider(board.id));

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      // El tablero inactivo se ve ligeramente atenuado (peek lateral)
      opacity: isActive ? 1.0 : 0.55,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isActive ? 1.0 : 0.97,
        child: tasksAsync.when(
          loading: () => const _TaskListSkeleton(),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (tasks) => _TaskList(board: board, tasks: tasks),
        ),
      ),
    );
  }
}

// ─── Lista de tareas con D&D ──────────────────────────────────────────────────

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.board, required this.tasks});

  final Board board;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return _EmptyBoard(boardName: board.name);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      proxyDecorator: _proxyDecorator,
      // Física con rebote en los extremos
      physics: const BouncingScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCardDraggable(
          key: ValueKey(task.id),
          task: task,
          boardId: board.id,
          index: index,
        );
      },
      onReorder: (oldIndex, newIndex) {
        // ReorderableListView ajusta el índice si se mueve hacia abajo
        if (newIndex > oldIndex) newIndex--;
        final reordered = List<Task>.from(tasks)
          ..insert(newIndex, tasks.removeAt(oldIndex));
        ref.read(taskActionsProvider.notifier).reorderTasks(
          board.id,
          reordered.map((t) => t.id).toList(),
        );
      },
    );
  }

  // Widget que se muestra mientras se arrastra (sombra elevada)
  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        final elevation = Tween<double>(begin: 0, end: 8).evaluate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );
        return Material(
          elevation: elevation,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.black26,
          child: child,
        );
      },
      child: child,
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.boardName});
  final String boardName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.15),
            ),
            const SizedBox(height: 12),
            Text(
              '$boardName está vacío',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Usa el campo de texto para añadir tareas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton mientras cargan las tareas ─────────────────────────────────────

class _TaskListSkeleton extends StatelessWidget {
  const _TaskListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _SkeletonCard(
        width: [1.0, 0.75, 0.9, 0.6][index],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.06);
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}