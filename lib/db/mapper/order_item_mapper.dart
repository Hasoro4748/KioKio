import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/models/order_model.dart';

class OrderItemMapper {
  static OrderItemModel fromData(OrderItem orderItem) {
    return OrderItemModel(
        productId: orderItem.productId,
        name: orderItem.productName,
        basePrice: orderItem.basePrice,
        quantity: orderItem.quantity);
  }

  static OrderItemsCompanion toCompanion(
    int orderId,
    OrderItemModel model,
  ) {
    return OrderItemsCompanion(
      orderId: Value(orderId),
      productId: Value(model.productId),
      productName: Value(model.name),
      basePrice: Value(model.basePrice),
      quantity: Value(model.quantity),
    );
  }
}
