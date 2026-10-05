import 'dart:convert';
import 'dart:io';

import 'package:kiosk/db/repositories/OrderRepository.dart';
import 'package:kiosk/db/repositories/product_repository.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:path_provider/path_provider.dart';

class OrderService {
  final OrderRepository repository;
  final ProductRepository productRepository;

  OrderService(this.repository, this.productRepository);

  Future<List<OrderModel>> loadOrders() async {
    return repository.getOrders();
  }

  /// 주문 추가
  Future<void> addOrder(OrderModel order) async {
    try {
      for (var item in order.items) {
        // 상세 정보를 가져와서 isSet 여부 확인
        final product =
            await productRepository.getProductDetail(item.productId);

        if (product != null) {
          if (product.isSet && product.componentIds.isNotEmpty) {
            // [중요] 세트 상품이면 구성품들 재고를 수량만큼 차감
            for (var subId in product.componentIds) {
              await _updateStockValue(subId, -item.quantity);
            }
          } else {
            // 일반 상품이면 본인 재고만 차감
            await _updateStockValue(product.id, -item.quantity);
          }
        }
      }
      return repository.addOrder(order);
    } catch (e) {
      print("주문 처리중 오류 발생 : $e");
      rethrow;
    }
  }

  Future<void> _updateStockValue(int id, int amount) async {
    final p = await productRepository.getProductSimple(id);
    if (p != null) {
      await productRepository.updateStock(
          id, (p.stock + amount).clamp(0, 99999).toInt());
    }
  }

  /// 승인 주문 추가
  Future<void> addApproveOrder(OrderModel order) async {
    try {
      return addOrder(order);
    } catch (e) {
      print("주문 승인 처리중 오류 발생 : $e");
      rethrow;
    }
  }

  /// 주문 상태 변경
  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
  }) {
    return repository.updateOrderState(orderId, status);
  }

  /// 주문 승인으로 변경
  Future<void> approveOrderStatus(OrderModel order) async {
    try {
      return repository.approveOrderState(order);
    } catch (e) {
      print("주문 처리중 오류 발생 : $e");
      rethrow;
    }
  }

  ///주문 취소로 변경
  Future<void> cancelOrderStatus(OrderModel order) async {
    try {
      for (var item in order.items) {
        // 1. 상품 상세 정보를 가져와서 세트 여부 확인 (중요)
        final product =
            await productRepository.getProductDetail(item.productId);

        if (product != null) {
          // 2. 세트 상품인 경우: 모든 구성품의 재고를 주문 수량만큼 다시 늘림 (+)
          if (product.isSet && product.componentIds.isNotEmpty) {
            for (var subId in product.componentIds) {
              await _updateStockValue(subId, item.quantity); // + 수량
            }
          }
          // 3. 일반 상품인 경우: 본인 재고만 늘림
          else {
            await _updateStockValue(product.id, item.quantity);
          }
        }
      }
      return repository.cancelOrderState(order);
    } catch (e) {
      print("주문 취소 처리중 오류 발생 : $e");
      rethrow;
    }
  }

  /// 주문 삭제
  Future<void> deleteOrder(OrderModel order) async {
    try {
      if (order.status != "취소") {
        for (var item in order.items) {
          final product =
              await productRepository.getProductDetail(item.productId);

          if (product != null) {
            if (product.isSet && product.componentIds.isNotEmpty) {
              for (var subId in product.componentIds) {
                await _updateStockValue(subId, item.quantity);
              }
            } else {
              await _updateStockValue(product.id, item.quantity);
            }
          }
        }
      }
      return repository.deleteOrder(order);
    } catch (e) {
      print("주문 삭제 처리중 오류 발생 : $e");
      rethrow;
    }
  }

  Future<void> updateOrderDiscount(int orderId, int discount) async {
    await repository.updateOrderDiscount(orderId, discount);
  }

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();

    final folder = Directory('${dir.path}/files');

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return File('${folder.path}/orders.json');
  }

  /// 주문 로컬 전체 저장
  static Future<void> saveLocalOrders(List<OrderModel> orders) async {
    final file = await _getFile();

    final jsonList = orders.map((e) => e.toJson()).toList();

    await file.writeAsString(
      jsonEncode(jsonList),
    );
  }

  /// 로컬 주문 전체 불러오기
  static Future<List<OrderModel>> loadLocalOrders() async {
    try {
      final file = await _getFile();

      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();

      if (content.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(content);

      return jsonList.map((e) => OrderModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
