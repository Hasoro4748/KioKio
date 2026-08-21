import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/providers/order_service_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
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

    ref.invalidate(productProvider);
  }

  Future<void> approveOrder(OrderModel order) async {
    await _service.approveOrderStatus(order);

    await reload();
  }

  Future<void> cancelOrder(OrderModel order) async {
    await _service.cancelOrderStatus(order);

    await reload();
  }

  Future<void> deleteOrder(OrderModel order) async {
    await _service.deleteOrder(order);
    await reload();
  }

  Future<void> addOrder(OrderModel order) async {
    await _service.addOrder(order);
    await reload();
  }

  Future<void> addApproveOrder(OrderModel order) async {
    await _service.addApproveOrder(order);
    await reload();
  }
}
