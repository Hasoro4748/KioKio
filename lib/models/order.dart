import 'package:kiosk/models/product.dart';

class Order {
  final String id;
  final List<OrderItem> items;
  final DateTime createdAt;
  String status; //처리중, 승인, 취소

  Order({
    required this.id,
    required this.items,
    required this.createdAt,
    this.status = '처리중',
  });

  int get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] ?? '처리중',
    );
  }
}

class OrderItem {
  final String productId;
  final String name;

  final int basePrice;
  final List<SelectedOption> selectedOptions;

  int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.basePrice,
    required this.selectedOptions,
    required this.quantity,
  });

  int get optPrice {
    final optionPrice = selectedOptions.fold(0, (sum, e) => sum + e.price);
    return optionPrice;
  }

  int get unitPrice {
    final optionPrice = selectedOptions.fold(0, (sum, e) => sum + e.price);
    return basePrice + optionPrice;
  }

  int get totalPrice {
    final optionPrice = selectedOptions.fold(0, (sum, e) => sum + e.price);
    return (basePrice + optionPrice) * quantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'basePrice': basePrice,
      'selectedOptions': selectedOptions.map((e) => e.toJson()).toList(),
      'quantity': quantity,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '알 수 없음',
      basePrice: json['basePrice'] ?? 0,
      selectedOptions: (json['selectedOptions'] as List? ?? [])
          .map((e) => SelectedOption.fromJson(e))
          .toList(),
      quantity: json['quantity'] ?? 1,
    );
  }
  String get optionText {
    return selectedOptions
        .map((e) => '${e.optionName}: ${e.itemName}')
        .join(', ');
  }
}

class SelectedOption {
  final String optionName; // 예: 사이즈
  final String itemName; // 예: 라지
  final int price; // 예: 추가금

  SelectedOption({
    required this.optionName,
    required this.itemName,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'optionName': optionName,
        'itemName': itemName,
        'price': price,
      };

  factory SelectedOption.fromJson(Map<String, dynamic> json) {
    return SelectedOption(
      optionName: json['optionName'] ?? '',
      itemName: json['itemName'] ?? '',
      price: json['price'] ?? 0,
    );
  }
}
