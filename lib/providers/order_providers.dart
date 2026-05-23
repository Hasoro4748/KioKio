import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/order.dart';
import 'package:kiosk/sevices/order_service.dart';

final orderProvider = NotifierProvider<OrderNotifier, List<Order>>(
  OrderNotifier.new,
);

class OrderNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    loadOrders();
    return [];
  }

  Future<void> loadOrders() async {
    state = await OrderService.loadOrders();
  }

  Future<void> approveOrder(String orderId) async {
    state = [
      for (final order in state)
        if (order.id == orderId) order.copyWith(status: '승인') else order,
    ];

    await OrderService.saveOrders(state);
  }

  Future<void> cancelOrder(String orderId) async {
    state = [
      for (final order in state)
        if (order.id == orderId) order.copyWith(status: '취소') else order,
    ];

    await OrderService.saveOrders(state);
  }

  Future<void> deleteOrder(String orderId) async {
    state = state.where((e) => e.id != orderId).toList();

    await OrderService.saveOrders(state);
  }

  Future<void> addOrder(Order order) async {
    state = [...state, order];

    await OrderService.saveOrders(state);
  }

  Future<void> updateStatus(
    String orderId,
    String status,
  ) async {
    final updatedOrders = state.map((order) {
      if (order.id == orderId) {
        order.status = status;
      }

      return order;
    }).toList();

    state = updatedOrders;

    await OrderService.saveOrders(state);
  }
}
