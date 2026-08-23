import 'package:drift/drift.dart';

class Themes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().unique()();
  Set<Column> get pKey => {id};
}
