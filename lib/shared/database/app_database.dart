import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/boards_dao.dart';
import 'daos/notes_dao.dart';
import 'daos/subtasks_dao.dart';
import 'daos/tasks_dao.dart';
import 'tables/boards_table.dart';
import 'tables/notes_table.dart';
import 'tables/subtasks_table.dart';
import 'tables/tasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Boards, Tasks, Subtasks, Notes],
  daos: [BoardsDao, TasksDao, SubtasksDao, NotesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await boardsDao.seedDefaultBoards();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(tasks, tasks.parentTaskTitle);
        }
        if (from < 3) {
          await m.addColumn(subtasks, subtasks.isPromoted);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'doboard.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}