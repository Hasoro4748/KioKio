import 'package:drift/drift.dart';
import 'package:kiosk/db/tables/categories.dart';
import 'package:kiosk/db/tables/products.dart';

class ProductCategories extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get productId => integer().references(
        Products,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get categoryId => integer().references(
        Categories,
        #id,
        onDelete: KeyAction.cascade,
      )();
}
