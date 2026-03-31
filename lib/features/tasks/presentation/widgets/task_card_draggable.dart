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
  });

  final Task task;
  final String boardId;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return LongPressDraggable<Task>(
      data: task,
      delay: const Duration(milliseconds: 350),
      // Haptic al iniciar el drag
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
      // Widget que sigue al dedo mientras se arrastra
      feedback: _DragFeedback(task: task),
      // Tarjeta original durante el drag: atenuada
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: TaskCard(task: task, boardId: boardId),
      ),
      child: TaskCard(task: task, boardId: boardId),
    );
  }
}

/// Widget flotante que sigue al dedo durante el drag.
/// Ligeramente rotado y elevado para dar sensación de "levantar".
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03, // ~1.7 grados
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(12),
        shadowColor: Colors.black38,
        child: SizedBox(
          // Ancho fijo igual al ancho de pantalla menos padding del PageView
          width: MediaQuery.of(context).size.width * 0.84,
          child: TaskCard(task: task, boardId: ''),
        ),
      ),
    );
  }
}