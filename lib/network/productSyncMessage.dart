import 'package:kiosk/models/product_model.dart';

enum SyncAction { initial, create, update, delete }

class ProductSyncMessage {
  final SyncAction action;
  final List<ProductModel> products;
  final Map<String, String>? imageDatas;
  final DateTime timestamp;

  ProductSyncMessage(
      {required this.action, required this.products, this.imageDatas})
      : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': 'PRODUCT_SYNC',
        'action': action.name,
        'products': products.map((p) => p.toJson()).toList(),
        'imageDatas': imageDatas,
        'timestamp': timestamp.toIso8601String(),
      };
}
