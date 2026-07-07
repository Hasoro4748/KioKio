class OrderModel {
  final int? id;
  final List<OrderItemModel> items;
  final DateTime createdAt;
  String status; // 처리중, 승인, 취소

  OrderModel({
    this.id,
    required this.items,
    required this.createdAt,
    this.status = '처리중',
  });

  int get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);
  //
  // Map<String, dynamic> toJson() => {
  //       'id': id,
  //       'items': items.map((e) => e.toJson()).toList(),
  //       'createdAt': createdAt.toIso8601String(),
  //       'status': status,
  //     };

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      items: (json['items'] as List)
          .map((e) => OrderItemModel.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] ?? '처리중',
    );
  }

  OrderModel copyWith({
    String? status,
  }) {
    return OrderModel(
      id: id,
      items: items,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        // TODO JSON 변환
      };
}

class OrderItemModel {
  final int productId;
  final String name;
  final int basePrice;
  int quantity;

  OrderItemModel({
    required this.productId,
    required this.name,
    required this.basePrice,
    required this.quantity,
  });

  int get unitPrice => basePrice;

  int get totalPrice => basePrice * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'basePrice': basePrice,
        'quantity': quantity,
      };

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '알 수 없음',
      basePrice: json['basePrice'] ?? 0,
      quantity: json['quantity'] ?? 1,
    );
  }
}
