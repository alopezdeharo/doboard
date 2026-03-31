import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/board.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';

/// Overlay que aparece en la parte inferior cuando el usuario arrastra
/// una tarjeta. Muestra los 4 tableros como destinos de drop.
class BoardDropTargets extends ConsumerWidget {
  const BoardDropTargets({
    super.key,
    required this.boards,
    required this.currentBoardIndex,
  });

  final List<Board> boards;
  final int currentBoardIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.55),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 32, 12, 16),
        child: Row(
          children: List.generate(boards.length, (i) {
            final isCurrentBoard = i == currentBoardIndex;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: isCurrentBoard
                    ? _CancelTarget(
                  onCancel: () =>
                  ref.read(dragStateProvider.notifier).state = null,
                )
                    : _BoardTarget(
                  board: boards[i],
                  onDrop: (task) {
                    HapticFeedback.mediumImpact();
                    ref
                        .read(taskActionsProvider.notifier)
                        .moveToBoard(task.id, boards[i].id);
                    ref.read(dragStateProvider.notifier).state = null;
                  },
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Target de un tablero destino.
class _BoardTarget extends StatefulWidget {
  const _BoardTarget({required this.board, required this.onDrop});
  final Board board;
  final ValueChanged<Task> onDrop;

  @override
  State<_BoardTarget> createState() => _BoardTargetState();
}

class _BoardTargetState extends State<_BoardTarget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (_) {
        setState(() => _isHovered = true);
        HapticFeedback.selectionClick();
        return true;
      },
      onLeave: (_) => setState(() => _isHovered = false),
      onAcceptWithDetails: (details) {
        setState(() => _isHovered = false);
        widget.onDrop(details.data);
      },
      builder: (_, candidateData, __) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withOpacity(0.25)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withOpacity(0.8)
                  : Colors.white.withOpacity(0.3),
              width: _isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.board.emoji,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                widget.board.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Target para cancelar el drag (tablero actual).
class _CancelTarget extends StatelessWidget {
  const _CancelTarget({required this.onCancel});
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✕', style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 4),
            Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}