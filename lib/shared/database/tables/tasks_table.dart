import 'package:drift/drift.dart';

import 'boards_table.dart';

@DataClassName('TaskData')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get boardId =>
      text().references(Boards, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get content => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  BoolColumn get isFrog => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  TextColumn get detectedKeyword => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  /// Título de la tarea padre original (si fue promovida desde subtarea).
  TextColumn get parentTaskTitle => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}