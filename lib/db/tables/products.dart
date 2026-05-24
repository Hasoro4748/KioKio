import 'package:drift/drift.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  /// JSON 문자열 저장
  TextColumn get theme => text()();

  TextColumn get seller => text()();

  TextColumn get categoryGroup => text()();

  IntColumn get basePrice => integer()();

  TextColumn get description => text()();

  IntColumn get stock => integer().withDefault(const Constant(0))();

  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
