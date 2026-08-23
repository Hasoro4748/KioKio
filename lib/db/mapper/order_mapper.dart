import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/models/order_model.dart';

class OrderMapper {
  static OrderModel fromData(OrderModel order) {
    return OrderModel(
        id: order.id, items: order.items, createdAt: order.createdAt);
  }

  static OrdersCompanion toCompanion(
    OrderModel model,
  ) {
    return OrdersCompanion(
      status: Value(model.status),
      createdAt: Value(model.createdAt),
      discount: Value(model.discount),
    );
  }
}
