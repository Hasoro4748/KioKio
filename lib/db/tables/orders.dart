import 'package:drift/drift.dart';

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get createdAt => dateTime()();

  TextColumn get status => text()();

  Set<Column> get pKey => {id};
}
