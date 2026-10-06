import 'package:drift/drift.dart';
import 'package:kiosk/db/tables/orders.dart';

class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get orderId => integer().references(
        Orders,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get productId => integer()();

  TextColumn get productName => text()();

  IntColumn get basePrice => integer()();

  IntColumn get quantity => integer()();
  IntColumn get discount => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get indexes => [
        {orderId},
      ];
}
