import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/providers/order_service_provider.dart';
import 'package:kiosk/sevices/order_service.dart';

final orderProvider = AsyncNotifierProvider<OrderNotifier, List<OrderModel>>(
  OrderNotifier.new,
);

class OrderNotifier extends AsyncNotifier<List<OrderModel>> {
  late final OrderService _service;

  @override
  Future<List<OrderModel>> build() {
    _service = ref.read(orderServiceProvider);

    return _service.loadOrders();
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => _service.loadOrders(),
    );
  }

  Future<void> approveOrder(int orderId) async {
    await _service.updateOrderStatus(orderId: orderId, status: '승인');
    await reload();
  }

  Future<void> cancelOrder(int orderId) async {
    await _service.updateOrderStatus(orderId: orderId, status: '취소');
    await reload();
  }

  Future<void> deleteOrder(int orderId) async {
    await _service.deleteOrder(orderId);
    await reload();
  }

  Future<void> addOrder(OrderModel order) async {
    await _service.addOrder(order);
    await reload();
  }
}
