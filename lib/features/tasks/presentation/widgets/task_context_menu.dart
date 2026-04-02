import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task.dart';
import '../providers/tasks_provider.dart';
import '../../../../features/boards/presentation/providers/boards_provider.dart';

class TaskContextMenu extends ConsumerWidget {
  const TaskContextMenu({
    super.key,
    required this.task,
    required this.boardId,
    required this.onClose,
  });

  final Task task;
  final String boardId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = ref.read(taskActionsProvider.notifier);
    final boardsAsync = ref.watch(visibleBoardsProvider);

    final otherBoards = boardsAsync.maybeWhen(
      data: (boards) => boards.where((b) => b.id != boardId).toList(),
      orElse: () => [],
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Completar ────────────────────────────────────────────
          _MenuItem(
            icon: task.isDone
                ? Icons.undo_rounded
                : Icons.check_circle_rounded,
            label: task.isDone ? 'Desmarcar' : 'Completar',
            color: theme.colorScheme.primary,
            onTap: () {
              actions.toggleDone(task.id, isDone: !task.isDone);
              onClose();
            },
          ),
          _Divider(),

          // ── Ver / editar ─────────────────────────────────────────
          _MenuItem(
            icon: Icons.edit_note_rounded,
            label: 'Ver / editar',
            onTap: () {
              onClose();
              context.push('/task/${task.id}');
            },
          ),
          _MenuItem(
            icon: Icons.sticky_note_2_outlined,
            label: task.hasNote ? 'Ver nota' : 'Añadir nota',
            onTap: () {
              onClose();
              context.push('/task/${task.id}/note');
            },
          ),
          _MenuItem(
            icon: Icons.center_focus_strong_rounded,
            label: 'Modo enfoque',
            onTap: () {
              onClose();
              context.push('/task/${task.id}/focus');
            },
          ),
          _Divider(),

          // ── Programar ────────────────────────────────────────────
          _MenuItem(
            icon: task.isScheduled
                ? Icons.event_busy_rounded
                : Icons.event_rounded,
            label: task.isScheduled
                ? 'Programada: ${_formatDate(task.scheduledDate!)} · Cancelar'
                : 'Programar para Hoy...',
            color: task.isScheduled
                ? theme.colorScheme.tertiary
                : null,
            onTap: () async {
              onClose();
              if (task.isScheduled) {
                actions.cancelSchedule(task.id);
              } else {
                await _showDatePicker(context, ref, task);
              }
            },
          ),
          _Divider(),

          // ── Mover a otro tablero ─────────────────────────────────
          if (otherBoards.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mover a',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            ...otherBoards.map((board) => _MenuItem(
              icon: null,
              emoji: board.emoji,
              label: board.name,
              onTap: () {
                actions.moveToBoard(task.id, board.id);
                onClose();
              },
            )),
            _Divider(),
          ],

          // ── Frog ─────────────────────────────────────────────────
          _MenuItem(
            icon: null,
            emoji: '🐸',
            label: task.isFrog ? 'Quitar rana' : 'Marcar como rana',
            onTap: () {
              task.isFrog
                  ? actions.removeFrog(task.id)
                  : actions.setFrog(task.id, boardId);
              onClose();
            },
          ),
          _MenuItem(
            icon: Icons.copy_rounded,
            label: 'Duplicar',
            onTap: () {
              actions.duplicateTask(task.id);
              onClose();
            },
          ),
          _Divider(),

          // ── Eliminar ─────────────────────────────────────────────
          _MenuItem(
            icon: Icons.delete_outline_rounded,
            label: 'Eliminar',
            color: theme.colorScheme.error,
            onTap: () {
              actions.deleteTask(task.id);
              onClose();
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final d = DateTime(date.year, date.month, date.day);
    if (d == DateTime(now.year, now.month, now.day)) return 'hoy';
    if (d == tomorrow) return 'mañana';
    return DateFormat('d MMM', 'es').format(date);
  }

  Future<void> _showDatePicker(
      BuildContext context, WidgetRef ref, Task task) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Mover a Hoy en esta fecha',
      confirmText: 'Programar',
      cancelText: 'Cancelar',
    );
    if (picked != null) {
      // Programar para las 00:00 del día seleccionado
      final scheduled = DateTime(picked.year, picked.month, picked.day);
      ref.read(taskActionsProvider.notifier).scheduleTask(task.id, scheduled);
    }
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.emoji,
    this.color,
  });

  final IconData? icon;
  final String? emoji;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          SizedBox(
            width: 20,
            child: emoji != null
                ? Text(emoji!, style: const TextStyle(fontSize: 14))
                : Icon(icon, size: 16, color: effectiveColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: effectiveColor)),
          ),
        ]),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
    );
  }
}