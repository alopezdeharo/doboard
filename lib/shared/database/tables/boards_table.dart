import 'package:drift/drift.dart';

@DataClassName('BoardData')
class Boards extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get subtitle => text().withLength(max: 100)();
  TextColumn get colorHex => text().withDefault(const Constant('#1D9E75'))();
  TextColumn get emoji => text().withDefault(const Constant('🐸'))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  BoolColumn get isVisible => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}