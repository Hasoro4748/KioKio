import 'package:drift/drift.dart';
import 'package:kiosk/db/tables/products.dart';
import 'package:kiosk/db/tables/sellers.dart';

class ProductSellers extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get productId => integer().references(
        Products,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get sellerId => integer().references(
        Sellers,
        #id,
        onDelete: KeyAction.cascade,
      )();
}
