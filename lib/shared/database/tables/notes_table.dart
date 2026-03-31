import 'package:drift/drift.dart';

import 'tasks_table.dart';

@DataClassName('NoteData')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get taskId =>
      text().unique().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get contentJson => text().withDefault(const Constant('[]'))();
  TextColumn get plainText => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}