import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/note.dart';
import '../providers/note_provider.dart';

class NoteEditorScreen extends HookConsumerWidget {
  const NoteEditorScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteByTaskProvider(taskId));

    return noteAsync.when(
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (note) => _NoteEditor(taskId: taskId, note: note),
    );
  }
}

class _NoteEditor extends HookConsumerWidget {
  const _NoteEditor({required this.taskId, this.note});
  final String taskId;
  final Note? note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final quillController = useMemoized(() {
      if (note != null &&
          note!.contentJson.isNotEmpty &&
          note!.contentJson != '[]') {
        try {
          final doc = Document.fromJson(
            List<dynamic>.from(jsonDecode(note!.contentJson)),
          );
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

    Future<void> save() async {
      final json =
      jsonEncode(quillController.document.toDelta().toJson());
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
      body: SafeArea(
        child: Column(
          children: [
            // ── Cabecera ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 28),
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    onPressed: () async {
                      if (hasUnsaved.value) await save();
                      if (context.mounted) context.pop();
                    },
                  ),
                  const Spacer(),
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
                ],
              ),
            ),

            // ── Toolbar ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                    theme.colorScheme.outlineVariant.withOpacity(0.4),
                    width: 0.5,
                  ),
                ),
              ),
              child: QuillSimpleToolbar(
                controller: quillController,
              ),
            ),

            // ── Editor ─────────────────────────────────────────────────
            Expanded(
              child: QuillEditor(
                controller: quillController,
                focusNode: focusNode,
                scrollController: scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}