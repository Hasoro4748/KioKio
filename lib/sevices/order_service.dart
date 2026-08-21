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
        final product =
            await productRepository.getProductSimple(item.productId);

        if (product != null) {
          int newStock = product.stock - item.quantity;
          if (newStock < 0) newStock = 0;

          await productRepository.updateStock(product.id, newStock);
        }
      }

      return repository.addOrder(order);
    } catch (e) {
      print("주문 처리중 오류 발생 : $e");
      rethrow;
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
        final product =
            await productRepository.getProductSimple(item.productId);

        if (product != null) {
          int newStock = product.stock + item.quantity;
          if (newStock < 0) newStock = 0;

          await productRepository.updateStock(product.id, newStock);
        }
      }
      return repository.cancelOrderState(order);
    } catch (e) {
      print("주문 처리중 오류 발생 : $e");
      rethrow;
    }
  }

  /// 주문 삭제
  Future<void> deleteOrder(OrderModel order) async {
    try {
      for (var item in order.items) {
        final product =
            await productRepository.getProductSimple(item.productId);

        if (product != null && order.status != "취소") {
          int newStock = product.stock + item.quantity;
          if (newStock < 0) newStock = 0;

          await productRepository.updateStock(product.id, newStock);
        }
      }
      return repository.deleteOrder(order);
    } catch (e) {
      print("주문 처리중 오류 발생 : $e");
      rethrow;
    }
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
