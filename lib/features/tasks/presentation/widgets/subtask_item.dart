import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subtask.dart';
import '../providers/tasks_provider.dart';

const _kMaxLength = 200;
const _kWarnAt    = 150;

class SubtaskItem extends ConsumerStatefulWidget {
  const SubtaskItem({
    super.key,
    required this.subtask,
    required this.taskId,
    required this.boardId,
  });

  final Subtask subtask;
  final String taskId;
  final String boardId;

  @override
  ConsumerState<SubtaskItem> createState() => _SubtaskItemState();
}

class _SubtaskItemState extends ConsumerState<SubtaskItem> {
  bool _isEditing = false;
  int  _charCount = 0;
  late final TextEditingController _ctrl;
  // Guardamos la referencia al notifier en initState para poder usarla
  // en dispose() de forma segura — ref.read() no está soportado en dispose().
  late final TaskActionsNotifier _actions;

  @override
  void initState() {
    super.initState();
    _ctrl    = TextEditingController(text: widget.subtask.title);
    _actions = ref.read(taskActionsProvider.notifier);
    _charCount = widget.subtask.title.length;
    _ctrl.addListener(() {
      if (mounted) setState(() => _charCount = _ctrl.text.length);
    });
  }

  @override
  void dispose() {
    // Mismo comportamiento que crear una subtarea nueva y pulsar atrás:
    // si el usuario sale con la edición activa, guardamos.
    if (_isEditing) {
      final v = _ctrl.text.trim();
      if (v.isNotEmpty && v != widget.subtask.title) {
        _actions.updateSubtaskTitle(widget.subtask.id, v);
      }
    }
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final v = _ctrl.text.trim();
    if (v.isNotEmpty && v != widget.subtask.title) {
      _actions.updateSubtaskTitle(widget.subtask.id, v);
    } else {
      _ctrl.text = widget.subtask.title; // revert si estaba vacío
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final subtask    = widget.subtask;
    final isPromoted = subtask.isPromoted;

    // Color del contador: normal → ámbar → rojo al llegar al tope
    final Color counterColor;
    if (_charCount >= _kMaxLength) {
      counterColor = theme.colorScheme.error;
    } else if (_charCount >= _kWarnAt) {
      counterColor = const Color(0xFFEFAA27);
    } else {
      counterColor = Colors.transparent; // oculto antes de 150
    }

    return Dismissible(
      key: ValueKey(subtask.id),
      direction:
          isPromoted ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: theme.colorScheme.error, size: 18),
      ),
      onDismissed: (_) => _actions.deleteSubtask(subtask.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ── Checkbox ───────────────────────────────────────────────
                GestureDetector(
                  onTap: isPromoted
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          _actions.toggleSubtaskDone(subtask.id,
                              isDone: !subtask.isDone);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isPromoted
                          ? Colors.transparent
                          : subtask.isDone
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isPromoted
                            ? theme.colorScheme.outline.withOpacity(0.2)
                            : subtask.isDone
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: isPromoted
                        ? Icon(Icons.open_in_new_rounded,
                            size: 10,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.25))
                        : subtask.isDone
                            ? Icon(Icons.check_rounded,
                                size: 11, color: theme.colorScheme.onPrimary)
                            : null,
                  ),
                ),
                const SizedBox(width: 10),

                // ── Título (editable al tap) ────────────────────────────────
                Expanded(
                  child: _isEditing
                      ? TextField(
                          controller: _ctrl,
                          autofocus: true,
                          maxLength: _kMaxLength,
                          maxLines: null,
                          buildCounter: (_, {required currentLength,
                                required isFocused, maxLength}) =>
                              null, // ocultamos el counter nativo de TextField
                          onSubmitted: (_) => _save(),
                          onTapOutside: (_) => _save(),
                          style: theme.textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : GestureDetector(
                          onTap: isPromoted
                              ? null
                              : () => setState(() {
                                    _isEditing = true;
                                    _charCount =
                                        widget.subtask.title.length;
                                  }),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subtask.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isPromoted
                                      ? subtask.isDone
                                          ? theme.colorScheme.onSurface
                                              .withOpacity(0.25)
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.35)
                                      : subtask.isDone
                                          ? theme.colorScheme.onSurface
                                              .withOpacity(0.35)
                                          : null,
                                  decoration: subtask.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: theme.colorScheme.onSurface
                                      .withOpacity(0.3),
                                ),
                              ),
                              if (isPromoted)
                                Text(
                                  '↳ movida a otra columna',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.25),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),

                // ── Contador de caracteres (solo en edición, desde 150) ─────
                if (_isEditing)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _charCount >= _kWarnAt ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '${_kMaxLength - _charCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: counterColor,
                        ),
                      ),
                    ),
                  ),

                // ── Botón promover (oculto mientras se edita) ───────────────
                if (!isPromoted && !_isEditing)
                  GestureDetector(
                    onTap: () => _actions.promoteSubtask(
                      subtaskId: subtask.id,
                      parentTaskId: widget.taskId,
                      targetBoardId: widget.boardId,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.25),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
