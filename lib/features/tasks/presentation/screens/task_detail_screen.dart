import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/automation_engine.dart';
import '../../../../features/settings/domain/entities/app_settings.dart';
import '../../../../features/notes/domain/entities/note.dart';
import '../../../../features/notes/presentation/providers/note_provider.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/priority.dart';
import '../providers/tasks_provider.dart';
import '../widgets/subtask_item.dart';

// Límite compartido con SubtaskItem y la BD (subtasks_table: max: 200)
const _kSubtaskMaxLength = 200;
const _kSubtaskWarnAt    = 150;
const _kMaxSubtasks      = 20;

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskByIdProvider(taskId));

    return taskAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (task) {
        if (task == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Tarea no encontrada')));
        }
        return _TaskDetailView(task: task);
      },
    );
  }
}

class _TaskDetailView extends HookConsumerWidget {
  const _TaskDetailView({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final titleCtrl = useTextEditingController(text: task.title);
    final contentCtrl = useTextEditingController(text: task.content ?? '');
    final isEditingTitle = useState(false);
    final isEditingContent = useState(false);
    final selectedPriority = useState(task.priority);
    final actions = ref.read(taskActionsProvider.notifier);

    useEffect(() {
      selectedPriority.value = task.priority;
      return null;
    }, [task.priority]);

    final noteAsync = ref.watch(noteByTaskProvider(task.id));
    final note = noteAsync.valueOrNull;

    final frogEnabled = ref.watch(settingsProvider).maybeWhen(
          data: (s) => s.frogEnabled,
          orElse: () => true,
        );
    final showFrog = task.isFrog && frogEnabled;

    void saveTitle() {
      final v = titleCtrl.text.trim();
      if (v.isNotEmpty && v != task.title) {
        final keyword = AutomationEngine.instance.detect(v);
        actions.updateTask(task.copyWith(title: v, detectedKeyword: keyword));
      }
      isEditingTitle.value = false;
    }

    void saveContent() {
      final v = contentCtrl.text.trim();
      actions.updateTask(task.copyWith(content: v.isEmpty ? null : v));
      isEditingContent.value = false;
    }

    void setPriority(Priority p) {
      selectedPriority.value = p;
      actions.updateTask(task.copyWith(priority: p));
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (isEditingContent.value) {
          final v = contentCtrl.text.trim();
          actions.updateTask(task.copyWith(content: v.isEmpty ? null : v));
        }
        if (isEditingTitle.value) {
          final v = titleCtrl.text.trim();
          if (v.isNotEmpty && v != task.title) {
            final keyword = AutomationEngine.instance.detect(v);
            actions.updateTask(
                task.copyWith(title: v, detectedKeyword: keyword));
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              _DetailAppBar(task: task),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showFrog) ...[
                          _FrogBanner(),
                          const SizedBox(height: 12),
                        ],

                        // ── Título editable ──────────────────────────────
                        GestureDetector(
                          onTap: () => isEditingTitle.value = true,
                          child: isEditingTitle.value
                              ? TextField(
                                  controller: titleCtrl,
                                  autofocus: true,
                                  onSubmitted: (_) => saveTitle(),
                                  onTapOutside: (_) => saveTitle(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero),
                                )
                              : Text(
                                  task.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // ── Selector de prioridad ────────────────────────
                        _PrioritySelector(
                          selected: selectedPriority.value,
                          onSelect: setPriority,
                        ),
                        const SizedBox(height: 20),

                        // ── Descripción editable ─────────────────────────
                        GestureDetector(
                          onTap: () => isEditingContent.value = true,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isEditingContent.value
                                ? TextField(
                                    controller: contentCtrl,
                                    autofocus: true,
                                    maxLines: null,
                                    onTapOutside: (_) => saveContent(),
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                            color:
                                                theme.colorScheme.onSurface),
                                    decoration: InputDecoration(
                                      hintText: 'Añade una descripción...',
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintStyle: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurface
                                                  .withOpacity(0.35)),
                                    ),
                                  )
                                : Text(
                                    contentCtrl.text.isNotEmpty
                                        ? contentCtrl.text
                                        : 'Toca para añadir descripción...',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: contentCtrl.text.isNotEmpty
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.35),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Nota ─────────────────────────────────────────
                        _NoteShortcut(taskId: task.id, note: note),
                        const SizedBox(height: 24),

                        // ── Subtareas ─────────────────────────────────────
                        _SubtaskSection(task: task),
                      ],
                    ),
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

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _DetailAppBar extends ConsumerWidget {
  const _DetailAppBar({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = ref.read(taskActionsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          onPressed: () => context.pop(),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          onPressed: () => context.push('/task/${task.id}/focus'),
        ),
        IconButton(
          icon: Icon(
            task.isDone
                ? Icons.check_circle_rounded
                : Icons.check_circle_outline_rounded,
            size: 22,
          ),
          color: task.isDone
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.5),
          onPressed: () {
            HapticFeedback.mediumImpact();
            actions.toggleDone(task.id, isDone: !task.isDone);
            if (!task.isDone) context.pop();
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          color: theme.colorScheme.error.withOpacity(0.7),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('¿Eliminar tarea?'),
                content: const Text('Esta acción no se puede deshacer.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );
            if (ok == true) {
              actions.deleteTask(task.id);
              if (context.mounted) context.pop();
            }
          },
        ),
      ]),
    );
  }
}

// ─── Selector de prioridad ────────────────────────────────────────────────────

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.selected, required this.onSelect});
  final Priority selected;
  final ValueChanged<Priority> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Priority.values.map((p) {
        final isSelected = p == selected;
        final color = _color(p, context);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? color : color.withOpacity(0.3),
                    width: isSelected ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(_label(p),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? color
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        )),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _color(Priority p, BuildContext ctx) => switch (p) {
        Priority.high => const Color(0xFFE24B4A),
        Priority.medium => const Color(0xFFEF9F27),
        Priority.low => Theme.of(ctx).colorScheme.onSurface.withOpacity(0.3),
      };

  String _label(Priority p) => switch (p) {
        Priority.high => 'Alta',
        Priority.medium => 'Media',
        Priority.low => 'Normal',
      };
}

// ─── Acceso a nota ────────────────────────────────────────────────────────────

class _NoteShortcut extends StatelessWidget {
  const _NoteShortcut({required this.taskId, required this.note});
  final String taskId;
  final Note? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNote = note != null && !note!.isEmpty;
    final preview = hasNote ? note!.plainText.trim() : null;

    return GestureDetector(
      onTap: () => context.push('/task/$taskId/note'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasNote
              ? theme.colorScheme.secondaryContainer.withOpacity(0.4)
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasNote
                ? theme.colorScheme.secondary.withOpacity(0.3)
                : theme.colorScheme.outlineVariant.withOpacity(0.4),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                hasNote
                    ? Icons.sticky_note_2_rounded
                    : Icons.add_comment_outlined,
                size: 18,
                color: hasNote
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: hasNote && preview != null && preview.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preview,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.65),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ver nota completa →',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                theme.colorScheme.secondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      hasNote
                          ? 'Ver nota completa →'
                          : 'Añadir nota extensa...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasNote
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sección de subtareas ─────────────────────────────────────────────────────

class _SubtaskSection extends HookConsumerWidget {
  const _SubtaskSection({required this.task});
  final Task task;

  // Parsea un sufijo xN al final del texto.
  // "dedicar 30 min x3" → ('dedicar 30 min', 3)
  // "tarea"             → ('tarea', 1)
  // "x3"               → ('x3', 1)  ← sin título base, se trata como literal
  static ({String title, int repeat}) _parseXn(String raw) {
    final match = RegExp(r'^(.*?)\s*[xX](\d+)$').firstMatch(raw);
    if (match == null) return (title: raw, repeat: 1);
    final base   = match.group(1)!.trim();
    final n      = int.tryParse(match.group(2)!) ?? 1;
    if (base.isEmpty || n <= 1) return (title: raw, repeat: 1);
    return (title: base, repeat: n);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme       = Theme.of(context);
    final isCollapsed = useState(false);
    final isAdding    = useState(false);
    final charCount   = useState(0);
    final inputCtrl   = useTextEditingController();
    final subtasksAsync = ref.watch(subtasksByTaskProvider(task.id));
    final actions     = ref.read(taskActionsProvider.notifier);

    // Actualizar contador al escribir
    useEffect(() {
      void listener() => charCount.value = inputCtrl.text.length;
      inputCtrl.addListener(listener);
      return () => inputCtrl.removeListener(listener);
    }, [inputCtrl]);

    Future<void> addSubtask() async {
      final raw = inputCtrl.text.trim();
      if (raw.isEmpty) {
        isAdding.value = false;
        return;
      }

      // Detectar sufijo xN  →  "dedicar 30 min x3" : title="dedicar 30 min", repeat=3
      final parsed    = _parseXn(raw);
      final baseTitle = parsed.title.length > _kSubtaskMaxLength
          ? parsed.title.substring(0, _kSubtaskMaxLength)
          : parsed.title;
      final repeat    = parsed.repeat;

      // Comprobar límite
      final currentCount = subtasksAsync.valueOrNull?.length ?? 0;
      final available    = _kMaxSubtasks - currentCount;

      if (repeat > available) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(
              available <= 0
                  ? 'Límite de $_kMaxSubtasks subtareas alcanzado'
                  : 'Solo puedes añadir $available subtarea${available == 1 ? '' : 's'} más (límite: $_kMaxSubtasks)',
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ));
        // No creamos nada: el usuario puede corregir el número
        return;
      }

      for (int i = 0; i < repeat; i++) {
        await actions.createSubtask(taskId: task.id, title: baseTitle);
      }
      inputCtrl.clear();
      charCount.value = 0;
    }

    // Mismo comportamiento que editar: guardar al salir de pantalla
    useEffect(() {
      return () {
        final raw = inputCtrl.text.trim();
        if (!isAdding.value || raw.isEmpty) return;

        // Parsear xN también al salir, respetando el límite
        final parsed    = _parseXn(raw);
        final baseTitle = parsed.title.length > _kSubtaskMaxLength
            ? parsed.title.substring(0, _kSubtaskMaxLength)
            : parsed.title;

        final currentCount = subtasksAsync.valueOrNull?.length ?? 0;
        final available    = _kMaxSubtasks - currentCount;
        final toCreate     = parsed.repeat.clamp(0, available);

        for (int i = 0; i < toCreate; i++) {
          actions.createSubtask(taskId: task.id, title: baseTitle);
        }
      };
    }, []);

    // Color del contador
    Color counterColor(int count) {
      if (count >= _kSubtaskMaxLength) return theme.colorScheme.error;
      if (count >= _kSubtaskWarnAt)    return const Color(0xFFEFAA27);
      return Colors.transparent;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Cabecera colapsable ──────────────────────────────────────────────
      GestureDetector(
        onTap: () => isCollapsed.value = !isCollapsed.value,
        child: Row(children: [
          Text('Subtareas',
              style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600)),
          subtasksAsync.maybeWhen(
            data: (subs) => subs.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                        '${subs.where((s) => s.isDone && !s.isPromoted).length}/${subs.where((s) => !s.isPromoted).length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.4)))),
            orElse: () => const SizedBox.shrink(),
          ),
          const Spacer(),
          AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: isCollapsed.value ? -0.25 : 0,
            child: Icon(Icons.expand_less_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ),
        ]),
      ),
      const SizedBox(height: 8),

      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: isCollapsed.value
            ? const SizedBox.shrink()
            : Column(children: [
                subtasksAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (subs) => Column(
                      children: subs
                          .map((s) => SubtaskItem(
                              subtask: s,
                              taskId: task.id,
                              boardId: task.boardId))
                          .toList()),
                ),
                if (isAdding.value) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                color: theme.colorScheme.outline
                                    .withOpacity(0.4),
                                width: 1.5))),
                    Expanded(
                      child: TextField(
                        controller: inputCtrl,
                        autofocus: true,
                        maxLength: _kSubtaskMaxLength,
                        maxLines: null,
                        // Ocultamos el contador nativo — usamos el nuestro
                        buildCounter: (_, {required currentLength,
                              required isFocused, maxLength}) => null,
                        onSubmitted: (_) => addSubtask(),
                        onTapOutside: (_) {
                          addSubtask();
                          isAdding.value = false;
                        },
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Nueva subtarea...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.35)),
                        ),
                      ),
                    ),
                    // ── Contador igual que en SubtaskItem ──────────────────
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity:
                          charCount.value >= _kSubtaskWarnAt ? 1.0 : 0.0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          '${_kSubtaskMaxLength - charCount.value}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: counterColor(charCount.value),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  // ── Tip xN ─────────────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Truco: añade ×3 al final para crear varias a la vez',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.28),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => isAdding.value = true,
                  child: Row(children: [
                    Icon(Icons.add_rounded,
                        size: 16,
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.35)),
                    const SizedBox(width: 6),
                    Text('Añadir subtarea',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.4))),
                  ]),
                ),
              ]),
      ),
    ]);
  }
}

// ─── Frog banner ─────────────────────────────────────────────────────────────

class _FrogBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Text('🐸', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text('Esta es tu tarea más importante hoy',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
