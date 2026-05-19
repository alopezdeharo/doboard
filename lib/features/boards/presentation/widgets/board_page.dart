import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/board.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import '../../../tasks/presentation/widgets/task_card.dart';
import '../../../tasks/presentation/widgets/task_card_draggable.dart';

// ─── BoardPage ────────────────────────────────────────────────────────────────

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

// ─── _TaskList ────────────────────────────────────────────────────────────────

class _TaskList extends ConsumerStatefulWidget {
  const _TaskList({required this.board, required this.tasks});

  final Board board;
  final List<Task> tasks;

  @override
  ConsumerState<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<_TaskList> {
  /// Tareas pendientes + las recién completadas aún "in place".
  List<Task> _pending = [];

  /// Tareas ya bajadas al desplegable (completedAt desc).
  List<Task> _completed = [];

  /// IDs marcados como done pero aún visibles en _pending (esperando timer).
  final Set<String> _pendingMoveIds = {};

  /// IDs que están ejecutando su animación de salida (collapse).
  final Set<String> _collapsingIds = {};

  Timer? _moveTimer;
  bool _completedExpanded = false;

  @override
  void initState() {
    super.initState();
    _splitTasks(widget.tasks, initial: true);
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_TaskList old) {
    super.didUpdateWidget(old);

    final newIds = widget.tasks.map((t) => t.id).toSet();

    // Limpiar pendingMoveIds/collapsingIds que ya no existen en la DB.
    _pendingMoveIds.retainAll(newIds);
    _collapsingIds.retainAll(newIds);

    final allLocalIds = {
      ..._pending.map((t) => t.id),
      ..._completed.map((t) => t.id),
    };

    if (!setEquals(allLocalIds, newIds)) {
      // Conjunto de IDs cambió → resincronización completa.
      _splitTasks(widget.tasks);
    } else {
      // Mismos IDs → merge preservando orden local y actualizando datos.
      final newById = {for (final t in widget.tasks) t.id: t};
      setState(() {
        _pending = _pending.map((t) => newById[t.id] ?? t).toList();
        _completed = _completed.map((t) => newById[t.id] ?? t).toList();
      });
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _splitTasks(List<Task> all, {bool initial = false}) {
    final pending = <Task>[];
    final completed = <Task>[];

    for (final t in all) {
      if (!t.isDone || _pendingMoveIds.contains(t.id)) {
        pending.add(t);
      } else {
        completed.add(t);
      }
    }

    completed.sort((a, b) {
      final ca = a.completedAt ?? a.updatedAt;
      final cb = b.completedAt ?? b.updatedAt;
      return cb.compareTo(ca);
    });

    if (initial) {
      _pending = pending;
      _completed = completed;
    } else {
      setState(() {
        _pending = pending;
        _completed = completed;
      });
    }
  }

  // ─── Toggle con delay ─────────────────────────────────────────────────────

  void _handleToggle(String taskId, bool isDone) {
    if (isDone) {
      _pendingMoveIds.add(taskId);
      setState(() {
        _pending = _pending
            .map((t) => t.id == taskId ? t.copyWith(isDone: true) : t)
            .toList();
      });
      _resetMoveTimer();
    } else {
      _pendingMoveIds.discard(taskId);
      _collapsingIds.discard(taskId);
      _moveTimer?.cancel();

      final fromCompleted =
          _completed.where((t) => t.id == taskId).firstOrNull;
      if (fromCompleted != null) {
        setState(() {
          _completed = _completed.where((t) => t.id != taskId).toList();
          _pending = [fromCompleted.copyWith(isDone: false), ..._pending];
        });
      } else {
        setState(() {
          _pending = _pending
              .map((t) => t.id == taskId ? t.copyWith(isDone: false) : t)
              .toList();
        });
      }
    }

    ref
        .read(taskActionsProvider.notifier)
        .toggleDone(taskId, isDone: isDone);
  }

  void _resetMoveTimer() {
    _moveTimer?.cancel();
    _moveTimer = Timer(
      const Duration(milliseconds: 1500),
      _startCollapseAnimation,
    );
  }

  /// Fase 1: añadir a _collapsingIds → AnimatedSize colapsa la tarjeta.
  void _startCollapseAnimation() {
    if (!mounted || _pendingMoveIds.isEmpty) return;
    setState(() {
      _collapsingIds.addAll(_pendingMoveIds);
    });
    // Fase 2: tras la animación, mover a completadas.
    Future.delayed(const Duration(milliseconds: 350), _flushCompleted);
  }

  /// Fase 2: mover de _pending → _completed.
  void _flushCompleted() {
    if (!mounted || _collapsingIds.isEmpty) return;

    final toFlush =
        _pending.where((t) => _collapsingIds.contains(t.id)).toList();

    setState(() {
      _pending.removeWhere((t) => _collapsingIds.contains(t.id));
      for (final task in toFlush) {
        _completed = [task, ..._completed];
      }
      _pendingMoveIds.removeAll(_collapsingIds);
      _collapsingIds.clear();
    });
  }

  // ─── Reordenamiento ───────────────────────────────────────────────────────

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _pending.removeAt(oldIndex);
      _pending.insert(newIndex, item);
    });
    ref.read(taskActionsProvider.notifier).reorderTasks(
          widget.board.id,
          _pending.map((t) => t.id).toList(),
        );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_pending.isEmpty && _completed.isEmpty) {
      return _EmptyBoard(boardName: widget.board.name);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      physics: const BouncingScrollPhysics(),
      onReorder: _onReorder,
      proxyDecorator: _proxyDecorator,
      buildDefaultDragHandles: false,
      // Tareas pendientes + footer (header completadas + lista completadas).
      itemCount: _pending.length + (_completed.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // Footer: desplegable de completadas.
        if (index == _pending.length) {
          return _CompletedSection(
            key: const ValueKey('__completed_section__'),
            completed: _completed,
            expanded: _completedExpanded,
            boardId: widget.board.id,
            onToggleDone: _handleToggle,
            onToggleExpanded: () =>
                setState(() => _completedExpanded = !_completedExpanded),
          );
        }

        final task = _pending[index];
        final isCollapsing = _collapsingIds.contains(task.id);

        return ReorderableDelayedDragStartListener(
          key: ValueKey(task.id),
          index: index,
          child: _AnimatedTaskSlot(
            isCollapsing: isCollapsing,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskCardDraggable(
                key: ValueKey(
                  '${task.id}_${task.isDone}_${task.priority.value}_${task.title.hashCode}',
                ),
                task: task,
                boardId: widget.board.id,
                index: index,
                onToggleDone: (isDone) => _handleToggle(task.id, isDone),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _proxyDecorator(
      Widget child, int index, Animation<double> animation) {
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

// ─── Slot con animación de colapso ────────────────────────────────────────────

class _AnimatedTaskSlot extends StatelessWidget {
  const _AnimatedTaskSlot({
    required this.isCollapsing,
    required this.child,
  });

  final bool isCollapsing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInCubic,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isCollapsing ? 0.0 : 1.0,
        child: isCollapsing ? const SizedBox(width: double.infinity) : child,
      ),
    );
  }
}

// ─── Sección de completadas ───────────────────────────────────────────────────

class _CompletedSection extends StatelessWidget {
  const _CompletedSection({
    super.key,
    required this.completed,
    required this.expanded,
    required this.boardId,
    required this.onToggleDone,
    required this.onToggleExpanded,
  });

  final List<Task> completed;
  final bool expanded;
  final String boardId;
  final void Function(String, bool) onToggleDone;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CompletedHeader(
          count: completed.length,
          expanded: expanded,
          onTap: onToggleExpanded,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: expanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final task in completed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TaskCard(
                          key: ValueKey('done_${task.id}'),
                          task: task,
                          boardId: boardId,
                          index: 0,
                          onToggleDone: (isDone) =>
                              onToggleDone(task.id, isDone),
                        ),
                      ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

// ─── Header del desplegable ───────────────────────────────────────────────────

class _CompletedHeader extends StatelessWidget {
  const _CompletedHeader({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withOpacity(0.4);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              turns: expanded ? 0.25 : 0,
              child: Icon(Icons.chevron_right_rounded, size: 18, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              'Completadas',
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _TaskListSkeleton extends StatelessWidget {
  const _TaskListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) =>
          _SkeletonCard(width: [1.0, 0.75, 0.9, 0.6][index]),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ─── Extension helper ─────────────────────────────────────────────────────────

extension on Set {
  void discard(Object? value) => remove(value);
}
