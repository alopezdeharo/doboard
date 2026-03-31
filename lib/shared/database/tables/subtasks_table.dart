import 'package:drift/drift.dart';

import 'tasks_table.dart';

@DataClassName('SubtaskData')
class Subtasks extends Table {
  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}