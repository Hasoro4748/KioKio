import 'package:drift/drift.dart';

class Themes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get displayOrder =>
      integer().withDefault(const Constant(0))(); // ★ 추가
  Set<Column> get pKey => {id};
}
