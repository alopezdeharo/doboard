import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../shared/database/app_database.dart';
import '../../domain/entities/note.dart';
import '../../../../shared/database/mappers.dart';

final noteByTaskProvider =
StreamProvider.family<Note?, String>((ref, taskId) {
  final db = ref.watch(appDatabaseProvider);
  return db.notesDao.watchNoteByTask(taskId).map((d) => d?.toNote());
});

class NoteActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> saveNote({
    required String taskId,
    String? existingNoteId,
    required String contentJson,
    required String plainText,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = existingNoteId ?? const Uuid().v4();
    await db.notesDao.upsertNote(NotesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      contentJson: Value(contentJson),
      plainText: Value(plainText),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  Future<void> deleteNote({required String taskId}) async {
    final db = ref.read(appDatabaseProvider);
    await db.notesDao.deleteNoteByTask(taskId);
  }
}

final noteActionsProvider =
NotifierProvider<NoteActionsNotifier, AsyncValue<void>>(
    NoteActionsNotifier.new);