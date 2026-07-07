import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/screens/counter/widgets/status_color.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';

class OrderDetailDialog extends ConsumerWidget {
  final OrderModel order;

  final Responsive rs;

  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final VoidCallback onApprove;

  const OrderDetailDialog({
    super.key,
    required this.order,
    required this.rs,
    required this.onDelete,
    required this.onCancel,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: rs.w(0.9),
        height: rs.h(0.8),
        child: Column(
          children: [
            /// 상단 헤더
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: statusBackgroundColor(order.status),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '주문번호: ${DateFormat('MMdd -').format(order.createdAt)} ${order.id}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '시간: ${DateFormat('yyyy년 MM월 dd일 - a hh시 mm분 ss초').format(order.createdAt)}',
                        ),
                        const SizedBox(height: 16),
                        const Text('─────────────'),
                        Row(
                          children: [
                            const Text(
                              '상태 : ',
                              style: TextStyle(fontSize: 20),
                            ),
                            Text(
                              order.status,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: statusColor(order.status),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: onDelete,
                            child: const Text(
                              '주문삭제',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            /// 주문 목록
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${TextUtil.money(item.unitPrice)}원',
                            textAlign: TextAlign.end,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${item.quantity}개',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${TextUtil.money(item.totalPrice)}원',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            /// 하단 버튼
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '총 금액',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${TextUtil.money(order.totalPrice)}원',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              order.status == '처리중' || order.status == '승인'
                                  ? onCancel
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                          ),
                          child: const Text('주문 취소'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: order.status == '처리중' ? onApprove : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                          ),
                          child: const Text('주문 승인'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
