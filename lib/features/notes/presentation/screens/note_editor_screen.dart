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

    // Versión del ticker para reconstruir el toolbar al cambiar la selección
    final toolbarTick = useState(0);

    useEffect(() {
      void onDocChanged() => hasUnsaved.value = true;
      void onSelChanged() => toolbarTick.value++;
      quillController.addListener(onDocChanged);
      quillController.addListener(onSelChanged);
      return () {
        quillController.removeListener(onDocChanged);
        quillController.removeListener(onSelChanged);
      };
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Cabecera ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                    theme.colorScheme.outlineVariant.withOpacity(0.3),
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

            // ── Editor ─────────────────────────────────────────────────
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

            // ── Toolbar inferior con estados visuales ──────────────────
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color:
                    theme.colorScheme.outlineVariant.withOpacity(0.4),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FormatBtn(
                        icon: Icons.format_bold_rounded,
                        tooltip: 'Negrita',
                        attribute: Attribute.bold,
                        controller: quillController,
                        tick: toolbarTick.value,
                      ),
                      _FormatBtn(
                        icon: Icons.format_italic_rounded,
                        tooltip: 'Cursiva',
                        attribute: Attribute.italic,
                        controller: quillController,
                        tick: toolbarTick.value,
                      ),
                      _FormatBtn(
                        icon: Icons.format_underline_rounded,
                        tooltip: 'Subrayado',
                        attribute: Attribute.underline,
                        controller: quillController,
                        tick: toolbarTick.value,
                      ),
                      _FormatBtn(
                        icon: Icons.format_strikethrough_rounded,
                        tooltip: 'Tachado',
                        attribute: Attribute.strikeThrough,
                        controller: quillController,
                        tick: toolbarTick.value,
                      ),
                      _Divider(),
                      _FormatBtn(
                        icon: Icons.check_box_outlined,
                        tooltip: 'Checkbox',
                        attribute: Attribute.unchecked,
                        controller: quillController,
                        tick: toolbarTick.value,
                      ),
                      _Divider(),
                      _ColorBtn(
                          controller: quillController,
                          isBackground: false),
                      _ColorBtn(
                          controller: quillController,
                          isBackground: true),
                      _Divider(),
                      _ActionBtn(
                        icon: Icons.undo_rounded,
                        tooltip: 'Deshacer',
                        enabled: quillController.hasUndo,
                        onTap: () => quillController.undo(),
                      ),
                      _ActionBtn(
                        icon: Icons.redo_rounded,
                        tooltip: 'Rehacer',
                        enabled: quillController.hasRedo,
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
}

// ─── Botón de formato con estado activo/inactivo ──────────────────────────────

class _FormatBtn extends StatelessWidget {
  const _FormatBtn({
    required this.icon,
    required this.attribute,
    required this.controller,
    required this.tick, // fuerza reconstrucción al cambiar selección
    this.tooltip = '',
  });
  final IconData icon;
  final Attribute attribute;
  final QuillController controller;
  final int tick;
  final String tooltip;

  bool get _isActive {
    try {
      final style = controller.getSelectionStyle();
      final val = style.attributes[attribute.key];
      if (attribute == Attribute.bold) return val?.value == true;
      if (attribute == Attribute.italic) return val?.value == true;
      if (attribute == Attribute.underline) return val?.value == true;
      if (attribute == Attribute.strikeThrough) return val?.value == true;
      if (attribute == Attribute.unchecked || attribute == Attribute.checked) {
        return val != null;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _isActive;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          if (active) {
            // Quitar el formato
            controller.formatSelection(Attribute.clone(attribute, null));
          } else {
            controller.formatSelection(attribute);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

// ─── Botón de acción (deshacer/rehacer) con estado enabled ───────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
    this.tooltip = '',
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? theme.colorScheme.onSurface.withOpacity(0.7)
                : theme.colorScheme.onSurface.withOpacity(0.25),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 20,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
    );
  }
}

// ─── Selector de color ────────────────────────────────────────────────────────

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
      message: isBackground ? 'Fondo' : 'Color texto',
      child: InkWell(
        onTap: () => _showColorPicker(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            isBackground
                ? Icons.format_color_fill_rounded
                : Icons.format_color_text_rounded,
            size: 20,
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
                    isBackground
                        ? controller.formatSelection(
                        const BackgroundAttribute(null))
                        : controller
                        .formatSelection(const ColorAttribute(null));
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
                    isBackground
                        ? controller
                        .formatSelection(BackgroundAttribute(hex))
                        : controller
                        .formatSelection(ColorAttribute(hex));
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: c, shape: BoxShape.circle),
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