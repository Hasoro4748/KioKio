import 'package:kiosk/db/app_database.dart';

class OrderItemDao {
  final AppDatabase db;

  OrderItemDao(this.db);

  Future<void> insertOrderItem(
    OrderItemsCompanion orderItem,
  ) {
    return db.into(db.orderItems).insert(orderItem);
  }

  Future<List<OrderItem>> getByOrderId(
    int orderId,
  ) {
    return (db.select(db.orderItems)..where((t) => t.orderId.equals(orderId)))
        .get();
  }
}
