import 'package:drift/drift.dart';

class Sellers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get displayOrder =>
      integer().withDefault(const Constant(0))(); // ★ 추가
}
