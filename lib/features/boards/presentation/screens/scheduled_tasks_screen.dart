import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';

/// Pestaña "Próximo" del MainShell.
/// Lista todas las tareas con fecha programada, agrupadas por día.
class ScheduledTasksScreen extends ConsumerWidget {
  const ScheduledTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledAsync = ref.watch(scheduledTasksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
              child: Row(
                children: [
                  const Text('📅', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próximo',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Tareas programadas',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 22),
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    onPressed: () => context.push('/settings'),
                    tooltip: 'Ajustes',
                  ),
                ],
              ),
            ),

            // ── Contenido ─────────────────────────────────────────────
            Expanded(
              child: scheduledAsync.when(
                loading: () =>
                const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return _EmptyState();
                  }
                  final grouped = _groupByDate(tasks);
                  final dates = grouped.keys.toList()..sort();

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      for (final date in dates) ...[
                        // Cabecera de fecha
                        SliverToBoxAdapter(
                          child: _DateHeader(date: date),
                        ),
                        // Tareas de ese día
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final task = grouped[date]![index];
                              return _ScheduledTaskTile(task: task);
                            },
                            childCount: grouped[date]!.length,
                          ),
                        ),
                      ],
                      // Espacio inferior para el NavigationBar
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, List<Task>> _groupByDate(List<Task> tasks) {
    final map = <DateTime, List<Task>>{};
    for (final task in tasks) {
      if (task.scheduledDate == null) continue;
      final d = task.scheduledDate!;
      final key = DateTime(d.year, d.month, d.day);
      map.putIfAbsent(key, () => []).add(task);
    }
    return map;
  }
}

// ─── Cabecera de fecha ─────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final String label;
    final Color color;

    if (date == today) {
      label = 'Hoy';
      color = theme.colorScheme.primary;
    } else if (date == tomorrow) {
      label = 'Mañana';
      color = theme.colorScheme.secondary;
    } else if (date.isBefore(today)) {
      label = 'Vencido · ${DateFormat('d MMM', 'es').format(date)}';
      color = theme.colorScheme.error;
    } else {
      label = DateFormat('EEEE, d MMM', 'es').format(date);
      // Capitalizar primera letra
      final capitalized = label[0].toUpperCase() + label.substring(1);
      return _buildHeader(context, capitalized,
          theme.colorScheme.onSurface.withOpacity(0.5));
    }

    return _buildHeader(context, label, color);
  }

  Widget _buildHeader(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fila de tarea programada ──────────────────────────────────────────────────

class _ScheduledTaskTile extends ConsumerWidget {
  const _ScheduledTaskTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = ref.read(taskActionsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: GestureDetector(
        onTap: () => context.push('/task/${task.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // ── Checkbox ──────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  actions.toggleDone(task.id, isDone: !task.isDone);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: task.isDone
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: task.isDone
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: task.isDone
                      ? Icon(Icons.check_rounded,
                      size: 13, color: theme.colorScheme.onPrimary)
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // ── Contenido ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (task.isFrog) ...[
                          const Text('🐸',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                        ],
                        if (task.detectedKeyword != null) ...[
                          Text(task.detectedKeyword!,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: task.isDone
                                  ? theme.colorScheme.onSurface
                                  .withOpacity(0.35)
                                  : theme.colorScheme.onSurface,
                              decoration: task.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Tablero de origen
                    const SizedBox(height: 3),
                    _BoardBadge(boardId: task.boardId),
                  ],
                ),
              ),

              // ── Cancelar programación ─────────────────────────────
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  actions.cancelSchedule(task.id);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.event_busy_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Badge del tablero de origen ──────────────────────────────────────────────

class _BoardBadge extends ConsumerWidget {
  const _BoardBadge({required this.boardId});
  final String boardId;

  static const _boardNames = {
    'board-hoy':     ('Hoy',     '🐸'),
    'board-rapidas': ('Rápidas', '⚡'),
    'board-calma':   ('Medias',  '⏳'),
    'board-prisa':   ('Largas',  '🕒'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final info = _boardNames[boardId];
    if (info == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(info.$2, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 3),
        Text(
          info.$1,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.15),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin tareas programadas',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Programa una tarea desde el menú ⋮ de cualquier tarjeta',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.25),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}