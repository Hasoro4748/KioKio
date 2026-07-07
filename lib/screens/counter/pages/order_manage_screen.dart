import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:kiosk/models/order_model.dart';
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

    final orderAsync = ref.watch(orderProvider);

    return Scaffold(
        body: orderAsync.when(
            loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
            error: (error, stack) => Center(
                  child: Text(
                    '주문을 불러오지 못했습니다.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
            data: (orders) {
              if (orders.isEmpty) {
                return const Center(
                  child: Text('주문이 없습니다.'),
                );
              }

              return Padding(
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
              );
            }));
  }

  Widget _buildOrderCard(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    Responsive rs,
  ) {
    return Card(
      color: statusBackgroundColor(order.status),
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(
            '주문번호: ${DateFormat('MMdd -').format(order.createdAt)} ${order.id}'),
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
    OrderModel order,
    Responsive rs,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return OrderDetailDialog(
          order: order,
          rs: rs,

          /// 삭제
          onDelete: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(orderProvider.notifier).deleteOrder(order.id!);
          },

          /// 취소
          onCancel: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(orderProvider.notifier).cancelOrder(order.id!);
          },

          /// 승인
          onApprove: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(orderProvider.notifier).approveOrder(order.id!);
          },
        );
      },
    );
  }
}
