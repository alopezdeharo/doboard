import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/subtask.dart';
import '../providers/tasks_provider.dart';
import 'task_context_menu.dart';

class TaskCard extends ConsumerStatefulWidget {
  const TaskCard({super.key, required this.task, required this.boardId});
  final Task task;
  final String boardId;

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
  

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final theme = Theme.of(context);
    final actions = ref.read(taskActionsProvider.notifier);

    return GestureDetector(
      onTap: _showMenu ? _closeMenu : () => context.push('/task/${task.id}'),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slidable(
            key: ValueKey(task.id),
            // Swipe izquierda → completar
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.28,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    HapticFeedback.mediumImpact();
                    actions.toggleDone(task.id, isDone: !task.isDone);
                  },
                  backgroundColor: task.isDone
                      ? theme.colorScheme.surfaceVariant
                      : theme.colorScheme.primary,
                  foregroundColor: task.isDone
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onPrimary,
                  icon: task.isDone ? Icons.undo_rounded : Icons.check_rounded,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ],
            ),
            // Swipe derecha → eliminar
            startActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.28,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    HapticFeedback.mediumImpact();
                    actions.deleteTask(task.id);
                  },
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
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
              onMenuTap: _toggleMenu,

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
    required this.onMenuTap,

  });

  final Task task;
  final String boardId;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = ref.read(taskActionsProvider.notifier);
    final isDone = task.isDone;
    final hasPriority = task.priority != Priority.low;

    // Subtareas: cargamos hasta 3 para mostrar preview
    final subtasksAsync = ref.watch(subtasksByTaskProvider(task.id));
    final subtasks = subtasksAsync.valueOrNull ?? [];

    final priorityColor = task.priority == Priority.low
        ? Colors.transparent
        : Color(int.parse(task.priority.colorHex.replaceFirst('#', '0xFF')));

    return Container(
      decoration: BoxDecoration(
        color: task.isFrog
            ? theme.colorScheme.primaryContainer.withOpacity(0.35)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: hasPriority
              ? BorderSide(color: priorityColor, width: 3)
              : BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 0.5),
          top: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 0.5),
          right: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 0.5),
          bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 6, 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Checkbox ──────────────────────────────────────────────
            _AnimatedCheckbox(
              isDone: isDone,
              priority: task.priority,
              onTap: () {
                HapticFeedback.selectionClick();
                actions.toggleDone(task.id, isDone: !isDone);
              },
            ),
            const SizedBox(width: 9),

            // ── Contenido ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge frog
                  if (task.isFrog) ...[
                    _FrogBadge(),
                    const SizedBox(height: 3),
                  ],

                  // Título + keyword
                  Row(children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isDone
                              ? theme.colorScheme.onSurface.withOpacity(0.35)
                              : theme.colorScheme.onSurface,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor:
                          theme.colorScheme.onSurface.withOpacity(0.35),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.detectedKeyword != null) ...[
                      const SizedBox(width: 4),
                      Text(task.detectedKeyword!,
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ]),

                  // Preview descripción
                  if (task.content != null &&
                      task.content!.isNotEmpty &&
                      !isDone) ...[
                    const SizedBox(height: 2),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.black, Colors.black, Colors.transparent],
                        stops: [0, 0.75, 1],
                      ).createShader(bounds),
                      blendMode: BlendMode.dstIn,
                      child: Text(
                        task.content!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                          theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ],

                  // ── Subtareas preview (máx 3 + fade) ─────────────
                  if (!isDone && subtasks.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _SubtaskPreview(subtasks: subtasks),
                  ],

                  // Badges nota
                  if (!isDone && task.hasNote) ...[
                    const SizedBox(height: 5),
                    _Badge(icon: Icons.notes_rounded, label: 'nota'),
                  ],
                ],
              ),
            ),

            // Añadir subtareas en el propio card
            GestureDetector(
              onTap: () => _showQuickSubtaskInput(context, ref, task),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                child: Icon(Icons.subdirectory_arrow_right_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ),
            ),

            // ── Botón menú ⋮ ──────────────────────────────────────────
            GestureDetector(
              onTap: onMenuTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 4, 0),
                child: Icon(Icons.more_vert_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.35)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickSubtaskInput(BuildContext context, WidgetRef ref, Task task) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Nueva subtarea...',
                border: InputBorder.none,
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  ref.read(taskActionsProvider.notifier)
                      .createSubtask(taskId: task.id, title: v.trim());
                }
                Navigator.pop(ctx);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(taskActionsProvider.notifier)
                    .createSubtask(taskId: task.id, title: controller.text.trim());
              }
              Navigator.pop(ctx);
            },
          ),
        ]),
      ),
    );
  }
}

// ─── Preview de subtareas con fade ───────────────────────────────────────────

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
        // Las subtareas visibles con fade en la última si hay más
        ShaderMask(
          shaderCallback: (bounds) {
            // Solo aplicar fade si hay subtareas ocultas
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
            children: visible.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(children: [
                Icon(
                  s.isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 12,
                  color: s.isDone
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    s.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: s.isDone
                          ? theme.colorScheme.onSurface.withOpacity(0.3)
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      decoration: s.isDone ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            )).toList(),
          ),
        ),
        // "+N más" si hay ocultas
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              '+$remaining más',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.35),
                fontSize: 10,
              ),
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
    required this.onTap,
  });

  final bool isDone;
  final Priority priority;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = switch (priority) {
      Priority.high => const Color(0xFFE24B4A),
      Priority.medium => const Color(0xFFEF9F27),
      Priority.low => theme.colorScheme.outline.withOpacity(0.5),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 20,
        height: 20,
        margin: const EdgeInsets.only(top: 1),
        decoration: BoxDecoration(
          color: isDone ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDone ? theme.colorScheme.primary : borderColor,
            width: 1.5,
          ),
        ),
        child: isDone
            ? Icon(Icons.check_rounded, size: 13,
            color: theme.colorScheme.onPrimary)
            : null,
      ),
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
        Text('Come esto primero',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            )),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.35);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 2),
      Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color)),
    ]);
  }
}