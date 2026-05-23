import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kiosk/models/order.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/screens/counter/widgets/order_detail_dialog.dart';
import 'package:kiosk/screens/counter/widgets/status_color.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';

class OrderManageScreen extends ConsumerWidget {
  const OrderManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rs = Responsive(context);

    final orders = ref.watch(orderProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            return _buildOrderCard(
              context,
              ref,
              order,
              rs,
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    WidgetRef ref,
    Order order,
    Responsive rs,
  ) {
    return Card(
      color: statusBackgroundColor(order.status),
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text('주문번호: ${order.id}'),
        subtitle: Text(
          '${order.items.length}개 상품 / ${TextUtil.money(order.totalPrice)}원',
        ),
        trailing: Text(
          order.status,
          style: TextStyle(
            color: statusColor(order.status),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        onTap: () {
          _showOrderDetailDialog(
            context,
            ref,
            order,
            rs,
          );
        },
      ),
    );
  }

  void _showOrderDetailDialog(
    BuildContext context,
    WidgetRef ref,
    Order order,
    Responsive rs,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return OrderDetailDialog(
          order: order,
          rs: rs,

          /// 삭제
          onDelete: () async {
            await ref.read(orderProvider.notifier).deleteOrder(order.id);

            if (context.mounted) {
              Navigator.pop(context);
            }
          },

          /// 취소
          onCancel: () async {
            await ref.read(orderProvider.notifier).cancelOrder(order.id);

            if (context.mounted) {
              Navigator.pop(context);
            }
          },

          /// 승인
          onApprove: () async {
            await ref.read(orderProvider.notifier).approveOrder(order.id);

            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }
}
