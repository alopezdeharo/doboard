import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/subtask.dart';
import '../providers/tasks_provider.dart';
import '../../../../features/settings/domain/entities/app_settings.dart';
import '../../../../features/notes/presentation/providers/note_provider.dart';
import 'task_context_menu.dart';

// ─── Paleta de colores por duración ──────────────────────────────────────────
// Centralizada aquí para que sea fácil de cambiar en el futuro.
abstract final class BoardColors {
  static const rapidas = Color(0xFFEFAA27); // ámbar   — urgencia, acción inmediata
  static const medias  = Color(0xFF4DB87A); // verde   — flujo, progreso constante
  static const largas  = Color(0xFF5B7FD4); // índigo  — profundidad, concentración
}

class TaskCard extends ConsumerStatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.boardId,
    required this.index,
    this.onToggleDone,
  });

  final Task task;
  final String boardId;
  final int index;
  final void Function(bool isDone)? onToggleDone;

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  bool _showMenu = false;

  void _toggleMenu() {
    HapticFeedback.selectionClick();
    setState(() => _showMenu = !_showMenu);
  }

  void _closeMenu() {
    if (_showMenu) setState(() => _showMenu = false);
  }

  void _handleToggle(bool isDone) {
    HapticFeedback.selectionClick();
    if (widget.onToggleDone != null) {
      widget.onToggleDone!(isDone);
    } else {
      ref.read(taskActionsProvider.notifier).toggleDone(
            widget.task.id,
            isDone: isDone,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return GestureDetector(
      onTap: _showMenu ? _closeMenu : () => context.push('/task/${task.id}'),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slidable(
            key: ValueKey(task.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.28,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    HapticFeedback.mediumImpact();
                    _handleToggle(!task.isDone);
                  },
                  backgroundColor: task.isDone
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: task.isDone
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onPrimary,
                  icon: task.isDone ? Icons.undo_rounded : Icons.check_rounded,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ],
            ),
            startActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.28,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    HapticFeedback.mediumImpact();
                    ref.read(taskActionsProvider.notifier).deleteTask(task.id);
                  },
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  icon: Icons.delete_outline_rounded,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ],
            ),
            child: _CardBody(
              task: task,
              boardId: widget.boardId,
              index: widget.index,
              onMenuTap: _toggleMenu,
              onToggleDone: _handleToggle,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _showMenu
                ? TaskContextMenu(
                    task: task,
                    boardId: widget.boardId,
                    onClose: _closeMenu,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Cuerpo de la tarjeta ─────────────────────────────────────────────────────

class _CardBody extends ConsumerWidget {
  const _CardBody({
    required this.task,
    required this.boardId,
    required this.index,
    required this.onMenuTap,
    required this.onToggleDone,
  });

  final Task task;
  final String boardId;
  final int index;
  final VoidCallback onMenuTap;
  final void Function(bool isDone) onToggleDone;

  static const _priorityBarWidth = 4.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDone = task.isDone;

    final subtasksAsync = ref.watch(subtasksByTaskProvider(task.id));
    final subtasks = subtasksAsync.valueOrNull ?? [];

    final noteAsync = ref.watch(noteByTaskProvider(task.id));
    final hasNote = noteAsync.valueOrNull != null;

    final frogEnabled = ref.watch(settingsProvider).maybeWhen(
          data: (s) => s.frogEnabled,
          orElse: () => true,
        );
    final showFrog = task.isFrog && frogEnabled;

    final showPriorityBar = !isDone && task.priority == Priority.high;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDone ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: showFrog
              ? theme.colorScheme.primaryContainer.withOpacity(0.35)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11.5),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Barra vertical de prioridad ───────────────────────────
                if (showPriorityBar)
                  Container(
                    width: _priorityBarWidth,
                    color: BoardColors.rapidas,
                  ),

                // ── Contenido de la tarjeta ───────────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      showPriorityBar ? 2 : 6,
                      9,
                      6,
                      9,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Checkbox ──────────────────────────────────────
                        GestureDetector(
                          onTap: () => onToggleDone(!isDone),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: _AnimatedCheckbox(
                                isDone: isDone,
                                priority: task.priority,
                              ),
                            ),
                          ),
                        ),
                        // ── Contenido ─────────────────────────────────────
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (task.isPromotedSubtask) ...[
                                  Text(
                                    '↳ ${task.parentTaskTitle}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.4),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                if (showFrog) ...[
                                  _FrogBadge(),
                                  const SizedBox(height: 3),
                                ],
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style:
                                            theme.textTheme.titleSmall?.copyWith(
                                          color: isDone
                                              ? theme.colorScheme.onSurface
                                                  .withOpacity(0.6)
                                              : theme.colorScheme.onSurface,
                                          decoration: isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationColor: theme
                                              .colorScheme.onSurface
                                              .withOpacity(0.4),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (task.detectedKeyword != null) ...[
                                      const SizedBox(width: 4),
                                      Text(task.detectedKeyword!,
                                          style:
                                              const TextStyle(fontSize: 14)),
                                    ],
                                  ],
                                ),
                                if (!isDone && task.priority != Priority.low) ...[
                                  const SizedBox(height: 5),
                                  _PriorityBadge(priority: task.priority),
                                ],
                                if (task.content != null &&
                                    task.content!.isNotEmpty &&
                                    !isDone) ...[
                                  const SizedBox(height: 3),
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.black,
                                        Colors.black,
                                        Colors.transparent
                                      ],
                                      stops: [0, 0.75, 1],
                                    ).createShader(bounds),
                                    blendMode: BlendMode.dstIn,
                                    child: Text(
                                      task.content!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                    ),
                                  ),
                                ],
                                if (!isDone && subtasks.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  _SubtaskPreview(subtasks: subtasks),
                                ],
                                if (!isDone && hasNote) ...[
                                  const SizedBox(height: 4),
                                  const Text('📝',
                                      style: TextStyle(fontSize: 12)),
                                ],
                                if (!isDone && task.isScheduled) ...[
                                  const SizedBox(height: 5),
                                  _ScheduledBadge(date: task.scheduledDate!),
                                ],
                              ],
                            ),
                          ),
                        ),
                        // ── Acciones derechas ──────────────────────────────
                        GestureDetector(
                          onTap: () =>
                              _showQuickSubtaskInput(context, ref, task),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                            child: Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              size: 16,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onMenuTap,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 2, 0),
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.35),
                            ),
                          ),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(2, 0, 4, 0),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickSubtaskInput(BuildContext context, WidgetRef ref, Task task) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 8,
          left: 16,
          right: 8,
          top: 16,
        ),
        child: Row(children: [
          Icon(Icons.subdirectory_arrow_right_rounded,
              size: 18,
              color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
              cursorColor: Theme.of(ctx).colorScheme.primary,
              decoration: InputDecoration(
                hintText: 'Nueva subtarea en "${task.title}"...',
                hintStyle: TextStyle(
                  color:
                      Theme.of(ctx).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  ref.read(taskActionsProvider.notifier).createSubtask(
                      taskId: task.id, title: v.trim());
                }
                Navigator.pop(ctx);
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.check_rounded,
                color: Theme.of(ctx).colorScheme.primary),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(taskActionsProvider.notifier).createSubtask(
                    taskId: task.id, title: controller.text.trim());
              }
              Navigator.pop(ctx);
            },
          ),
        ]),
      ),
    );
  }
}

// ─── Badge de prioridad ───────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final Priority priority;

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (priority) {
      Priority.high => (
          'Importante',
          BoardColors.rapidas.withOpacity(0.18),
          BoardColors.rapidas,
        ),
      Priority.medium => (
          'Normal',
          BoardColors.medias.withOpacity(0.15),
          BoardColors.medias,
        ),
      Priority.low => ('', Colors.transparent, Colors.transparent),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Preview subtareas ────────────────────────────────────────────────────────

class _SubtaskPreview extends StatelessWidget {
  const _SubtaskPreview({required this.subtasks});
  final List<Subtask> subtasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = subtasks.take(3).toList();
    final remaining = subtasks.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) {
            if (remaining == 0) {
              return const LinearGradient(
                      colors: [Colors.black, Colors.black])
                  .createShader(bounds);
            }
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.black, Colors.transparent],
              stops: [0.0, 0.6, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: visible
                .map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(children: [
                        Icon(
                          s.isDone
                              ? Icons.check_box_rounded
                              : s.isPromoted
                                  ? Icons.open_in_new_rounded
                                  : Icons.check_box_outline_blank_rounded,
                          size: 12,
                          color: s.isDone
                              ? theme.colorScheme.primary
                              : s.isPromoted
                                  ? theme.colorScheme.onSurface
                                      .withOpacity(0.25)
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            s.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: s.isDone
                                  ? theme.colorScheme.onSurface
                                      .withOpacity(0.3)
                                  : s.isPromoted
                                      ? theme.colorScheme.onSurface
                                          .withOpacity(0.25)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                              decoration: s.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontStyle:
                                  s.isPromoted ? FontStyle.italic : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ))
                .toList(),
          ),
        ),
        if (remaining > 0)
          Text(
            '+$remaining más',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.35),
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}

// ─── Checkbox animado ─────────────────────────────────────────────────────────

class _AnimatedCheckbox extends StatelessWidget {
  const _AnimatedCheckbox({
    required this.isDone,
    required this.priority,
  });

  final bool isDone;
  final Priority priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = switch (priority) {
      Priority.high   => BoardColors.rapidas,
      Priority.medium => BoardColors.medias,
      Priority.low    => theme.colorScheme.outline.withOpacity(0.5),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isDone ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDone ? theme.colorScheme.primary : borderColor,
          width: 1.5,
        ),
      ),
      child: isDone
          ? Icon(Icons.check_rounded,
              size: 14, color: theme.colorScheme.onPrimary)
          : null,
    );
  }
}

// ─── Badge frog ───────────────────────────────────────────────────────────────

class _FrogBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🐸', style: TextStyle(fontSize: 10)),
        const SizedBox(width: 3),
        Text(
          'Come esto primero',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }
}

// ─── Badge de fecha programada ────────────────────────────────────────────────

class _ScheduledBadge extends StatelessWidget {
  const _ScheduledBadge({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    final String label;
    if (d == today) {
      label = '📅 hoy';
    } else if (d == today.add(const Duration(days: 1))) {
      label = '📅 mañana';
    } else {
      label = '📅 ${date.day}/${date.month}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: theme.colorScheme.tertiary,
        ),
      ),
    );
  }
}
