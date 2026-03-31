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

/// Base de datos principal de doboard.
///
/// Uso:
/// ```dart
/// final db = ref.watch(appDatabaseProvider);
/// final tasks = await db.tasksDao.watchTasksByBoard('board-hoy').first;
/// ```
///
/// El generador de Drift crea app_database.g.dart con el código de acceso.
/// Ejecutar: flutter pub run build_runner build --delete-conflicting-outputs
@DriftDatabase(
  tables: [Boards, Tasks, Subtasks, Notes],
  daos: [BoardsDao, TasksDao, SubtasksDao, NotesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Constructor para tests: usa base de datos en memoria (sin archivo).
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // Se llama solo la primera vez que se crea la DB
      onCreate: (m) async {
        await m.createAll();
        // Insertar los 4 tableros por defecto
        await boardsDao.seedDefaultBoards();
      },

      // Se llama cuando schemaVersion aumenta
      onUpgrade: (m, from, to) async {
        // v1 → v2: añadir columna timer_duration a tasks
        // if (from < 2) {
        //   await m.addColumn(tasks, tasks.timerDuration);
        // }
      },

      // Validación de integridad al abrir (solo en debug)
      beforeOpen: (details) async {
        // Activar foreign keys en SQLite (desactivadas por defecto)
        await customStatement('PRAGMA foreign_keys = ON');

        if (details.wasCreated) {
          // La migración onCreate ya insertó los datos semilla
          return;
        }
      },
    );
  }
}

/// Abre la conexión a la base de datos en el directorio de documentos del SO.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'doboard.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}