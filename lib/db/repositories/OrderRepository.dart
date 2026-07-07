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

  //전체 주문 조회
  Future<List<OrderModel>> getOrders() async {
    final orders = await orderDao.getAllOrders();

    final result = <OrderModel>[];

    for (final o in orders) {
      final orderItems = await orderItemDao.getByOrderId(o.id);

      result.add(OrderModel(
          id: o.id,
          items: orderItems.map((e) => OrderItemMapper.fromData(e)).toList(),
          status: o.status,
          createdAt: o.createdAt));
    }

    return result;
  }

  Future<OrderModel> getOrderDetail(int orderId) async {
    final order = await orderDao.getById(orderId);
    final orderItems = await orderItemDao.getByOrderId(orderId);

    return (OrderModel(
        id: orderId,
        items: orderItems.map((e) => OrderItemMapper.fromData(e)).toList(),
        createdAt: order!.createdAt));
  }

  Future<void> addOrder(OrderModel order) async {
    await db.transaction(
      () async {
        final orderId =
            await orderDao.insertOrder(OrderMapper.toCompanion(order));

        for (final item in order.items) {
          await orderItemDao
              .insertOrderItem(OrderItemMapper.toCompanion(orderId, item));
        }
      },
    );
  }

  Future<void> updateOrderState(int orderId, String status) async {
    await orderDao.updateStatus(orderId, status);
  }

  Future<void> deleteOrder(int orderId) async {
    await orderDao.deleteOrder(orderId);
  }
}
