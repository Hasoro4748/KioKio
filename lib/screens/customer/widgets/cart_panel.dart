// lib/screens/customer/widgets/cart_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';

class CartPanel extends ConsumerWidget {
  final List<OrderItemModel> cart;
  final int totalValue;
  final int totalPrice;

  final VoidCallback onClear;
  final VoidCallback onCheckout;

  final Function(OrderItemModel item) onIncrease;
  final Function(OrderItemModel item) onDecrease;
  final Function(OrderItemModel item)? onRemoveItem; // ★ 개별 삭제 콜백 추가
  final int Function(int productId) getStock;

  const CartPanel({
    super.key,
    required this.cart,
    required this.totalValue,
    required this.totalPrice,
    required this.onClear,
    required this.onCheckout,
    required this.onIncrease,
    required this.onDecrease,
    this.onRemoveItem,
    required this.getStock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rs = Responsive(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: rs.h(0.01)),
      child: Column(
        children: [
          SizedBox(height: rs.h(0.01)),

          /// 상단 헤더
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rs.w(0.02)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        color: PageColors.cateSelect, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '장바구니',
                      style: TextStyle(
                        fontSize: rs.font(20),
                        fontWeight: FontWeight.w900,
                        fontFamily: 'GmarketSans',
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (cart.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: PageColors.cateSelect,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalValue',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (cart.isNotEmpty)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.grey),
                    label: const Text('전체 삭제',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
              ],
            ),
          ),

          const Divider(thickness: 1, height: 16),

          /// 장바구니 리스트
          Expanded(
            child: cart.isEmpty
                ? _buildEmptyCartState(rs)
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return _buildCartItemCard(context, item, rs);
                    },
                  ),
          ),

          /// 하단 결제 정보 및 결제하기 버튼
          if (cart.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(rs.padding(16)),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '전체 수량',
                              style: TextStyle(
                                fontSize: rs.font(15),
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${totalValue}개',
                              style: TextStyle(
                                fontSize: rs.font(16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '총 결제 금액',
                              style: TextStyle(
                                fontSize: rs.font(17),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${TextUtil.money(totalPrice)}원',
                              style: TextStyle(
                                fontSize: rs.font(22),
                                fontWeight: FontWeight.w900,
                                color: PageColors.price,
                                fontFamily: 'GmarketSans',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PageColors.cateSelect,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        '총 $totalValue개 • ${TextUtil.money(totalPrice)}원 결제하기',
                        style: TextStyle(
                          fontSize: rs.font(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 2단 슬림 장바구니 개별 품목 카드 위젯
  Widget _buildCartItemCard(
      BuildContext context, OrderItemModel item, Responsive rs) {
    final maxStock = getStock(item.productId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1단: 상품명 + 개별 [X] 삭제 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: rs.font(14),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ★ 개별 삭제 X 버튼
              InkWell(
                onTap: () {
                  if (onRemoveItem != null) {
                    onRemoveItem!(item);
                  } else {
                    onDecrease(item);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2단: 슬림해진 수량 조절 버튼 (좌측) + 총 금액 (우측)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ★ 슬림 콤팩트 수량 조절 피프
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => onDecrease(item),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: PageColors.cateSelect,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontSize: rs.font(13),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: item.quantity < maxStock
                          ? () => onIncrease(item)
                          : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: item.quantity < maxStock
                              ? PageColors.cateSelect
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 개별 품목 금액
              Text(
                '${TextUtil.money(item.totalPrice)}원',
                style: TextStyle(
                  fontSize: rs.font(15),
                  fontWeight: FontWeight.w900,
                  color: PageColors.price,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 장바구니가 비어있을 때의 뷰
  Widget _buildEmptyCartState(Responsive rs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_shopping_cart_outlined,
              size: 54, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '장바구니가 비어있습니다.',
            style: TextStyle(
              fontSize: rs.font(16),
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '원하는 메뉴를 터치해 담아보세요!',
            style: TextStyle(
              fontSize: rs.font(13),
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
