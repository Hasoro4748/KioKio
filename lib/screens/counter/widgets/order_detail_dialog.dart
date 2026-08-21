import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/screens/counter/widgets/status_color.dart';
import 'package:kiosk/theme/common_theme.dart';
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
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: rs.isMobile ? rs.w(0.9) : rs.w(0.45), // 너비 축소
        height: rs.h(0.75),
        child: Column(
          children: [
            /// 상단 헤더 영역 (컴팩트하게 수정)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16), // 24 -> 16
              decoration: BoxDecoration(
                color: statusBackgroundColor(order.status).withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor(order.status),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.status,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No. ${order.id}',
                            style: const TextStyle(
                              fontSize: 16, // 20 -> 16
                              fontWeight: FontWeight.w900,
                              color: PageColors.textBlue,
                              fontFamily: 'GmarketSans',
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close,
                            size: 20, color: PageColors.textBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '주문일시: ${DateFormat('yyyy.MM.dd HH:mm:ss').format(order.createdAt)}',
                    style: TextStyle(
                        color: PageColors.textBlue.withOpacity(0.5),
                        fontSize: 12),
                  ),
                ],
              ),
            ),

            /// 주문 품목 헤더 (폰트 및 높이 축소)
            Container(
              color: PageColors.buttonBack.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: const [
                  Expanded(
                      flex: 3,
                      child: Text('상품명',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: PageColors.textBlue))),
                  Expanded(
                      child: Text('단가',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: PageColors.textBlue))),
                  Expanded(
                      child: Text('수량',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: PageColors.textBlue))),
                  Expanded(
                      child: Text('금액',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: PageColors.textBlue))),
                ],
              ),
            ),

            /// 주문 품목 리스트 (간격 축소)
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: order.items.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text(item.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500))),
                        Expanded(
                            child: Text(TextUtil.money(item.unitPrice),
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 13))),
                        Expanded(
                            child: Text('${item.quantity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13))),
                        Expanded(
                          child: Text(
                            TextUtil.money(item.totalPrice),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: PageColors.price),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            /// 하단 결제 정보 및 액션 버튼 (컴팩트하게 수정)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('최종 결제 금액',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        '${TextUtil.money(order.totalPrice)}원',
                        style: const TextStyle(
                          fontSize: 22, // 26 -> 22
                          fontWeight: FontWeight.w900,
                          color: DefaultColors.red,
                          fontFamily: 'GmarketSans',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // 삭제 버튼을 아이콘 버튼으로 작게 배치하거나 텍스트 버튼으로 변경
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            color: DefaultColors.red, size: 22),
                        tooltip: '주문 삭제',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              (order.status == '처리중' || order.status == '승인')
                                  ? onCancel
                                  : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DefaultColors.red,
                            side: const BorderSide(color: DefaultColors.red),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12), // 16 -> 12
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('주문 취소',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: order.status == '처리중' ? onApprove : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PageColors.cateSelect,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12), // 16 -> 12
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('주문 승인',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
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
