import 'package:drift/drift.dart';

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get createdAt => dateTime()();

  TextColumn get status => text()();

  IntColumn get discount => integer().withDefault(const Constant(0))();

  Set<Column> get pKey => {id};
}
