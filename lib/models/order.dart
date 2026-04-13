import 'package:kiosk/models/product.dart';

class Order {
  final String id;
  final List<OrderItem> items;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.items,
    required this.createdAt,
  });

  int get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class OrderItem {
  final Product product;
  int quantity;

  OrderItem({required this.product, required this.quantity});

  int get totalPrice => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': product.id,
      'quantity': quantity,
    };
  }
}
