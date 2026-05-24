import 'package:drift/drift.dart';
import 'package:kiosk/db/tables/products.dart';

class ProductImages extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get productId => integer().references(
        Products,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get imagePath => text()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  BoolColumn get isThumbnail => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
}
