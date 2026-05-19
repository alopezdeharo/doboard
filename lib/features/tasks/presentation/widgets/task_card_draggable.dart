import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import '../providers/tasks_provider.dart';
import 'task_card.dart';

/// Envuelve TaskCard con LongPressDraggable.
/// Al mantener pulsado:
///   1. Haptic feedback
///   2. La tarjeta original se atenúa (isDragging)
///   3. Aparece el overlay de BoardDropTargets (en BoardsScreen)
///   4. Al soltar sobre un DragTarget → moveToBoard()
class TaskCardDraggable extends ConsumerWidget {
  const TaskCardDraggable({
    super.key,
    required this.task,
    required this.boardId,
    required this.index,
    this.onToggleDone,
  });

  final Task task;
  final String boardId;
  final int index;

  /// Callback para interceptar el toggle desde board_page (lógica de delay).
  /// Si es null, TaskCard llama directamente al provider.
  final void Function(bool isDone)? onToggleDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LongPressDraggable<Task>(
      data: task,
      delay: const Duration(milliseconds: 350),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
        ref.read(dragStateProvider.notifier).state = task;
      },
      onDragEnd: (_) {
        ref.read(dragStateProvider.notifier).state = null;
      },
      onDraggableCanceled: (_, __) {
        ref.read(dragStateProvider.notifier).state = null;
      },
      feedback: _DragFeedback(task: task),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: TaskCard(
          task: task,
          boardId: boardId,
          index: index,
          onToggleDone: onToggleDone,
        ),
      ),
      child: TaskCard(
        task: task,
        boardId: boardId,
        index: index,
        onToggleDone: onToggleDone,
      ),
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(12),
        shadowColor: Colors.black38,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.84,
          child: TaskCard(task: task, boardId: '', index: 0),
        ),
      ),
    );
  }
}
