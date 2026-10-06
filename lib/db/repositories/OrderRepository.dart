import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/db/dao/order_dao.dart';
import 'package:kiosk/db/dao/order_item_dao.dart';
import 'package:kiosk/db/mapper/order_item_mapper.dart';
import 'package:kiosk/db/mapper/order_mapper.dart';
import 'package:kiosk/models/order_model.dart';

class OrderRepository {
  final AppDatabase db;
  final OrderDao orderDao;
  final OrderItemDao orderItemDao;

  OrderRepository(
      {required this.db, required this.orderDao, required this.orderItemDao});

  // 전체 주문 조회 (N+1 쿼리 제거 최적화)
  Future<List<OrderModel>> getOrders() async {
    // 1. 전체 주문 목록 조회 (1번 쿼리)
    final orders = await orderDao.getAllOrders();
    if (orders.isEmpty) return [];

    // 2. 전체 주문 항목 조회 (1번 쿼리)
    final allOrderItems = await db.select(db.orderItems).get();
    final itemMap = <int, List<OrderItemModel>>{};

    for (var item in allOrderItems) {
      itemMap
          .putIfAbsent(item.orderId, () => [])
          .add(OrderItemMapper.fromData(item));
    }

    // 3. 인메모리에서 즉시 결합
    final result = <OrderModel>[];
    for (final o in orders) {
      final items = itemMap[o.id] ?? [];
      result.add(OrderModel(
        id: o.id,
        items: items,
        status: o.status,
        createdAt: o.createdAt,
        discount: o.discount,
      ));
    }

    return result;
  }

  Future<OrderModel> getOrderDetail(int orderId) async {
    final order = await orderDao.getById(orderId);
    final orderItems = await orderItemDao.getByOrderId(orderId);

    if (order == null) {
      return OrderModel(
        id: orderId,
        items: [],
        createdAt: DateTime.now(),
        status: '알수없음',
        discount: 0,
      );
    }

    return OrderModel(
      id: orderId,
      items: orderItems.map((e) => OrderItemMapper.fromData(e)).toList(),
      createdAt: order.createdAt,
      status: order.status,
      discount: order.discount,
    );
  }

  Future<void> addOrder(OrderModel order) async {
    await db.transaction(() async {
      // 1. 주문 헤더 저장
      final orderId =
          await orderDao.insertOrder(OrderMapper.toCompanion(order));

      // 2. 주문 항목 컴패니언 리스트 생성
      final companions = order.items
          .map((item) => OrderItemMapper.toCompanion(orderId, item))
          .toList();

      // ★ 3. batch.insertAll 로 단 1번에 모든 주문 항목 일괄 저장! (5~10배 빠름)
      if (companions.isNotEmpty) {
        await db.batch((batch) {
          batch.insertAll(db.orderItems, companions);
        });
      }
    });
  }

  Future<void> updateOrderState(int orderId, String status) async {
    await orderDao.updateStatus(orderId, status);
  }

  Future<void> updateOrderDiscount(int orderId, int discount) async {
    await orderDao.updateDiscount(orderId, discount);
  }

  Future<void> approveOrderState(OrderModel order) async {
    await orderDao.approveStatus(order);
  }

  Future<void> cancelOrderState(OrderModel order) async {
    await orderDao.cancelStatus(order);
  }

  Future<void> deleteOrder(OrderModel order) async {
    await orderDao.deleteOrder(order);
  }
}
