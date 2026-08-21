import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/theme/common_theme.dart';

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
      backgroundColor: baseBackgroundColor[100],
      appBar: AppBar(
        toolbarHeight: 50, // 앱바 높이 축소
        title: const Text(
          '실시간 주문 관리',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontWeight: FontWeight.w900,
            fontSize: 16, // 폰트 크기 축소
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('주문을 불러오지 못했습니다.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13)),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: PageColors.textBlue.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  const Text('접수된 주문이 없습니다.',
                      style: TextStyle(
                          color: PageColors.textBlue,
                          fontWeight: FontWeight.w500,
                          fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(10), // 패딩 축소 (16 -> 10)
            itemCount: orders.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 8), // 간격 축소 (12 -> 8)
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, ref, order, rs);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    Responsive rs,
  ) {
    return InkWell(
      onTap: () => _showOrderDetailDialog(context, ref, order, rs),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 1. 상태 표시 바 (두께 축소 6 -> 4)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor(order.status),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),

              // 2. 주문 정보 영역
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10), // 패딩 축소
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${order.id} (${DateFormat('HH:mm').format(order.createdAt)})',
                            style: const TextStyle(
                              fontSize: 13, // 15 -> 13
                              fontWeight: FontWeight.w900,
                              color: PageColors.textBlue,
                              fontFamily: 'GmarketSans',
                            ),
                          ),
                          // 상태 칩 (크기 축소)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor(order.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: statusColor(order.status)
                                      .withOpacity(0.3)),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: statusColor(order.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 10, // 12 -> 10
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 12,
                              color: PageColors.textBlue.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(
                            '${order.items.length}개 품목',
                            style: TextStyle(
                                color: PageColors.textBlue.withOpacity(0.5),
                                fontSize: 11), // 13 -> 11
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. 가격 영역
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${TextUtil.money(order.totalPrice)}원',
                  style: const TextStyle(
                    fontSize: 15, // 18 -> 15
                    fontWeight: FontWeight.w900,
                    color: PageColors.price,
                    fontFamily: 'GmarketSans',
                  ),
                ),
              ),

              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
              const SizedBox(width: 4),
            ],
          ),
        ),
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
          onDelete: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(orderProvider.notifier).deleteOrder(order);
          },
          onCancel: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(orderProvider.notifier).cancelOrder(order);
          },
          onApprove: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(orderProvider.notifier).approveOrder(order);
          },
        );
      },
    );
  }
}
