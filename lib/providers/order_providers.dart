import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/providers/order_service_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/providers/product_service_provider.dart';
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

    await _syncRestoredProducts(order);

    await reload();
  }

  Future<void> deleteOrder(OrderModel order) async {
    await _service.deleteOrder(order);

    if (order.status != "취소") {
      await _syncRestoredProducts(order);
    }

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

  Future<void> _syncRestoredProducts(OrderModel order) async {
    try {
      // 최신화된 전체 상품 리스트 가져오기
      final allProducts = await ref.read(productServiceProvider).loadProducts();

      // 이번 주문으로 인해 재고가 변한 상품들만 추출
      final affectedProductIds = order.items.map((i) => i.productId).toSet();
      final updatedProducts =
          allProducts.where((p) => affectedProductIds.contains(p.id)).toList();

      if (updatedProducts.isNotEmpty) {
        // ProductNotifier에 있는 브로드캐스트 로직 재사용
        ref.read(productProvider.notifier).updateSyncManual(updatedProducts);
      }
    } catch (e) {
      print("취소 재고 동기화 중 오류: $e");
    }
  }
}
