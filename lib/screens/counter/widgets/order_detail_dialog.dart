import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/providers/order_providers.dart';
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
    final ordersAsync = ref.watch(orderProvider);
    final currentOrder = ordersAsync.maybeWhen(
      data: (list) => list.firstWhereOrNull((o) => o.id == order.id) ?? order,
      orElse: () => order,
    );
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      // 1. 전체 테두리 둥글기 강화 (16 -> 24)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: rs.isMobile ? rs.w(0.9) : rs.w(0.45),
          height: rs.h(0.8), // 높이를 살짝 키워 할인 영역 확보
          child: Column(
            children: [
              // --- 3. 헤더 영역 개선 ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                decoration: BoxDecoration(
                  // 상태별 배경색을 연하게 깔아줌
                  color: statusColor(order.status).withOpacity(0.05),
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
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor(order.status),
                                borderRadius:
                                    BorderRadius.circular(8), // 배지도 둥글게
                              ),
                              child: Text(
                                order.status,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '주문번호 No. ${order.id}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: PageColors.textBlue,
                                  fontFamily: 'GmarketSans'),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded,
                              size: 24, color: PageColors.textBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          '주문일시: ${DateFormat('yyyy.MM.dd HH:mm:ss').format(order.createdAt)}',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- 4. 리스트 헤더 (모서리 없이 깔끔하게) ---
              Container(
                color: Colors.grey[50],
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: const [
                    Expanded(
                        flex: 3,
                        child: Text('상품명',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey))),
                    Expanded(
                        child: Text('단가',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey))),
                    Expanded(
                        child: Text('수량',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey))),
                    Expanded(
                        child: Text('금액',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey))),
                  ],
                ),
              ),

              // --- 5. 주문 품목 리스트 ---
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: order.items.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text(item.name,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87))),
                          Expanded(
                              child: Text(TextUtil.money(item.unitPrice),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey))),
                          Expanded(
                              child: Text('${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                            child: Text(
                              TextUtil.money(item.totalPrice),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  fontSize: 15,
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

              // --- 6. 하단 정보 및 버튼 영역 ---
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildPriceDetailRow(
                        '상품 합계', currentOrder.subTotalPrice, rs),
                    if (currentOrder.discount > 0)
                      _buildPriceDetailRow('할인 금액', -currentOrder.discount, rs,
                          color: Colors.red),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('최종 결제 금액'),
                        Text(
                          '${TextUtil.money(currentOrder.totalPrice)}원',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: DefaultColors.red,
                              fontFamily: 'GmarketSans'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        // 삭제 버튼
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12)),
                          child: IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_forever_rounded,
                                color: DefaultColors.red, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // [추가] 할인 버튼
                        if ((order.status == '처리중'))
                          SizedBox(
                            width: 80,
                            child: OutlinedButton(
                              onPressed: () => _showDiscountDialog(
                                  context, ref, currentOrder),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: order.discount > 0
                                    ? Colors.red
                                    : PageColors.cateSelect,
                                side: BorderSide(
                                    color: order.discount > 0
                                        ? Colors.red
                                        : PageColors.cateSelect,
                                    width: 1.5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                  currentOrder.discount > 0 ? '할인중' : '할인'),
                            ),
                          ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                (order.status == '처리중' || order.status == '승인')
                                    ? onCancel
                                    : null,
                            // ... 취소 버튼 스타일 유지 ...
                            child: Text('주문 취소',
                                style: TextStyle(
                                    color: order.status == '취소'
                                        ? Colors.grey
                                        : Colors.red,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: order.status == '처리중' ? onApprove : null,
                            child: const Text('주문 승인',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  void _showDiscountDialog(
      BuildContext context, WidgetRef ref, OrderModel latestOrder) {
    final controller = TextEditingController(
        text: latestOrder.discount > 0 ? latestOrder.discount.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('할인 금액 수정'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration:
              const InputDecoration(suffixText: '원', hintText: '할인할 금액 입력'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(orderProvider.notifier)
                  .updateOrderDiscount(latestOrder, 0);
              Navigator.pop(ctx);
            },
            child: const Text('할인 취소', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              int amount = int.tryParse(controller.text) ?? 0;
              if (amount > latestOrder.subTotalPrice) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('할인액이 주문 합계보다 클 수 없습니다.')));
                return;
              }
              ref
                  .read(orderProvider.notifier)
                  .updateOrderDiscount(latestOrder, amount);
              Navigator.pop(ctx);
            },
            child: const Text('적용'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetailRow(String label, int amount, Responsive rs,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
          Text('${TextUtil.money(amount)}원',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}
