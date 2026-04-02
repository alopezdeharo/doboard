import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/note.dart';
import '../providers/note_provider.dart';
import '../../../../core/providers/repository_providers.dart';

class NoteEditorScreen extends HookConsumerWidget {
  const NoteEditorScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteByTaskProvider(taskId));

    // Cargamos el título de la tarea para mostrarlo arriba
    final taskTitle = useState<String>('');
    useEffect(() {
      ref.read(taskRepositoryProvider).getTaskById(taskId).then((t) {
        if (t != null) taskTitle.value = t.title;
      });
      return null;
    }, [taskId]);

    return noteAsync.when(
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (note) => _NoteEditor(
        taskId: taskId,
        note: note,
        taskTitle: taskTitle.value,
      ),
    );
  }
}

class _NoteEditor extends HookConsumerWidget {
  const _NoteEditor({
    required this.taskId,
    this.note,
    required this.taskTitle,
  });
  final String taskId;
  final Note? note;
  final String taskTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final quillController = useMemoized(() {
      if (note != null &&
          note!.contentJson.isNotEmpty &&
          note!.contentJson != '[]') {
        try {
          final doc = Document.fromJson(
              List<dynamic>.from(jsonDecode(note!.contentJson)));
          return QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (_) {}
      }
      return QuillController.basic();
    }, [note?.contentJson]);

    final focusNode = useFocusNode();
    final hasUnsaved = useState(false);
    final scrollController = useScrollController();

    useEffect(() {
      void listener() => hasUnsaved.value = true;
      quillController.addListener(listener);
      return () => quillController.removeListener(listener);
    }, [quillController]);

    // Detecta "- " al inicio de línea → bullet list
    // Las listas numeradas (1. 2. 3.) las maneja Quill internamente
    useEffect(() {
      quillController.document.changes.listen((_) {
        _detectBulletPattern(quillController);
      });
      return null;
    }, [quillController]);

    Future<void> save() async {
      final json = jsonEncode(quillController.document.toDelta().toJson());
      final plain = quillController.document.toPlainText().trim();
      await ref.read(noteActionsProvider.notifier).saveNote(
        taskId: taskId,
        existingNoteId: note?.id,
        contentJson: json,
        plainText: plain,
      );
      hasUnsaved.value = false;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // Resizes para que el toolbar no quede tapado por el teclado
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Cabecera: título de la tarea + acciones ────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 28),
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  onPressed: () async {
                    if (hasUnsaved.value) await save();
                    if (context.mounted) context.pop();
                  },
                ),
                Expanded(
                  child: Text(
                    taskTitle.isNotEmpty ? taskTitle : 'Nota',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasUnsaved.value)
                  TextButton(
                    onPressed: save,
                    child: Text('Guardar',
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500)),
                  ),
                if (note != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20,
                        color: theme.colorScheme.error.withOpacity(0.6)),
                    onPressed: () async {
                      await ref
                          .read(noteActionsProvider.notifier)
                          .deleteNote(taskId: taskId);
                      if (context.mounted) context.pop();
                    },
                  ),
              ]),
            ),

            // ── Editor con márgenes generosos ─────────────────────────
            Expanded(
              child: QuillEditor(
                controller: quillController,
                focusNode: focusNode,
                scrollController: scrollController,
                config: QuillEditorConfig(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  placeholder: 'Escribe tu nota aquí...',
                  autoFocus: note == null,
                ),
              ),
            ),

            // ── Toolbar en la parte inferior (como Google Keep) ────────
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolbarBtn(
                        icon: Icons.format_bold_rounded,
                        tooltip: 'Negrita',
                        onTap: () => quillController
                            .formatSelection(Attribute.bold),
                      ),
                      _ToolbarBtn(
                        icon: Icons.format_italic_rounded,
                        tooltip: 'Cursiva',
                        onTap: () => quillController
                            .formatSelection(Attribute.italic),
                      ),
                      _ToolbarBtn(
                        icon: Icons.format_underline_rounded,
                        tooltip: 'Subrayado',
                        onTap: () => quillController
                            .formatSelection(Attribute.underline),
                      ),
                      _ToolbarBtn(
                        icon: Icons.format_strikethrough_rounded,
                        tooltip: 'Tachado',
                        onTap: () => quillController
                            .formatSelection(Attribute.strikeThrough),
                      ),
                      _ToolbarDivider(),
                      _ToolbarBtn(
                        icon: Icons.check_box_outlined,
                        tooltip: 'Checkbox',
                        onTap: () => quillController
                            .formatSelection(Attribute.unchecked),
                      ),
                      _ToolbarDivider(),
                      _ColorBtn(
                          controller: quillController,
                          isBackground: false),
                      _ColorBtn(
                          controller: quillController,
                          isBackground: true),
                      _ToolbarDivider(),
                      _ToolbarBtn(
                        icon: Icons.undo_rounded,
                        tooltip: 'Deshacer',
                        onTap: () => quillController.undo(),
                      ),
                      _ToolbarBtn(
                        icon: Icons.redo_rounded,
                        tooltip: 'Rehacer',
                        onTap: () => quillController.redo(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Detecta "- " al inicio de línea y convierte a bullet list.
  /// Las listas numeradas (1. 2. 3.) las gestiona Quill internamente.
  void _detectBulletPattern(QuillController ctrl) {
    try {
      final sel = ctrl.selection;
      if (!sel.isCollapsed) return;
      final index = sel.baseOffset;
      if (index < 2) return;
      final text = ctrl.document.toPlainText();
      if (index > text.length) return;
      int lineStart = text.lastIndexOf('\n', index - 1);
      lineStart = lineStart < 0 ? 0 : lineStart + 1;
      final lineText = text.substring(lineStart, index);
      if (lineText == '- ') {
        ctrl.replaceText(lineStart, 2, '', null);
        ctrl.formatText(lineStart, 0, Attribute.ul);
      }
    } catch (_) {}
  }
}

// ─── Botones del toolbar ──────────────────────────────────────────────────────

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 22,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 22,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
    );
  }
}

class _ColorBtn extends StatelessWidget {
  const _ColorBtn({required this.controller, required this.isBackground});
  final QuillController controller;
  final bool isBackground;

  static const _colors = [
    Colors.red, Colors.orange, Colors.yellow,
    Colors.green, Colors.blue, Colors.purple, Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isBackground ? 'Color de fondo' : 'Color de letra',
      child: InkWell(
        onTap: () => _showColorPicker(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            isBackground
                ? Icons.format_color_fill_rounded
                : Icons.format_color_text_rounded,
            size: 22,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isBackground ? 'Color de fondo' : 'Color de letra',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    if (isBackground) {
                      controller.formatSelection(
                          const BackgroundAttribute(null));
                    } else {
                      controller.formatSelection(const ColorAttribute(null));
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.5),
                    ),
                    child: Icon(Icons.block_rounded,
                        size: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)),
                  ),
                ),
                ..._colors.map((c) => GestureDetector(
                  onTap: () {
                    final hex =
                        '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                    if (isBackground) {
                      controller
                          .formatSelection(BackgroundAttribute(hex));
                    } else {
                      controller.formatSelection(ColorAttribute(hex));
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration:
                    BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}