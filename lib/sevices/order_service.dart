import 'dart:convert';
import 'dart:io';

import 'package:kiosk/models/order.dart';
import 'package:path_provider/path_provider.dart';

class OrderService {
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();

    final folder = Directory('${dir.path}/files');

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return File('${folder.path}/orders.json');
  }

  /// 주문 전체 불러오기
  static Future<List<Order>> loadOrders() async {
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

      return jsonList.map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 주문 전체 저장
  static Future<void> saveOrders(List<Order> orders) async {
    final file = await _getFile();

    final jsonList = orders.map((e) => e.toJson()).toList();

    await file.writeAsString(
      jsonEncode(jsonList),
    );
  }

  /// 주문 추가
  static Future<void> addOrder(Order order) async {
    final orders = await loadOrders();
    print("주문삽입");
    orders.add(order);

    await saveOrders(orders);
  }

  /// 주문 상태 변경
  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final orders = await loadOrders();

    final index = orders.indexWhere((e) => e.id == orderId);

    if (index == -1) return;

    orders[index] = orders[index].copyWith(
      status: status,
    );

    await saveOrders(orders);
  }

  /// 주문 삭제
  static Future<void> deleteOrder(String orderId) async {
    final orders = await loadOrders();

    orders.removeWhere((e) => e.id == orderId);

    await saveOrders(orders);
  }
}
