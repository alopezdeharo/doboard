import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/notes_table.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  // ─── Lecturas ──────────────────────────────────────────────────────────────

  /// Stream de la nota asociada a una tarea.
  /// Emite null si la tarea no tiene nota todavía.
  Stream<NoteData?> watchNoteByTask(String taskId) {
    return (select(notes)..where((n) => n.taskId.equals(taskId)))
        .watchSingleOrNull();
  }

  Future<NoteData?> getNoteByTask(String taskId) {
    return (select(notes)..where((n) => n.taskId.equals(taskId)))
        .getSingleOrNull();
  }

  // ─── Escrituras ────────────────────────────────────────────────────────────

  /// Upsert: crea la nota si no existe, o actualiza si ya existe.
  Future<void> upsertNote(NotesCompanion note) {
    return into(notes).insertOnConflictUpdate(note);
  }

  Future<int> deleteNoteByTask(String taskId) {
    return (delete(notes)..where((n) => n.taskId.equals(taskId))).go();
  }
}