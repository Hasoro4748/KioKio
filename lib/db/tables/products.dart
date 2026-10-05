import 'package:drift/drift.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  IntColumn get basePrice => integer()();

  TextColumn get description => text()();

  IntColumn get stock => integer().withDefault(const Constant(0))();

  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();

  IntColumn get displayOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  BoolColumn get isSet => boolean().withDefault(const Constant(false))();

  TextColumn get componentIds => text().nullable()();
}
