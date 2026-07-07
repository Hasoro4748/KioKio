import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';

class OrderDao {
  final AppDatabase db;

  OrderDao(this.db);

  Future<int> insertOrder(
    OrdersCompanion order,
  ) {
    return db.into(db.orders).insert(order);
  }

  Future<List<Order>> getAllOrders() {
    return (db.select(db.orders)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .get();
  }

  Future<List<Order>> getAllOrdersAsc() {
    return (db.select(db.orders)
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  Future<void> updateStatus(
    int orderId,
    String status,
  ) {
    return (db.update(db.orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        status: Value(status),
      ),
    );
  }

  //삭제 - 미구현
  Future<void> deleteOrder(int orderId) {
    return (db.delete(db.orders)..where((t) => t.id.equals(orderId))).go();
  }

  //id로 찾기
  Future<Order?> getById(int orderId) {
    return (db.select(db.orders)..where((t) => t.id.equals(orderId)))
        .getSingleOrNull();
  }
}
