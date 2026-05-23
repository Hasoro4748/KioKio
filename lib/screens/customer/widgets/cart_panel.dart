import 'package:flutter/material.dart';
import 'package:kiosk/models/order.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';

class CartPanel extends StatelessWidget {
  final List<OrderItem> cart;

  final int totalValue;
  final int totalPrice;

  final VoidCallback onClear;
  final VoidCallback onCheckout;

  final Function(OrderItem item) onIncrease;
  final Function(OrderItem item) onDecrease;

  final int Function(String productId) getStock;

  const CartPanel({
    super.key,
    required this.cart,
    required this.totalValue,
    required this.totalPrice,
    required this.onClear,
    required this.onCheckout,
    required this.onIncrease,
    required this.onDecrease,
    required this.getStock,
  });

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: rs.h(0.01),
      ),
      child: Column(
        children: [
          SizedBox(height: rs.h(0.015)),

          /// 제목
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: rs.w(0.01),
            ),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  '장바구니',
                  style: TextStyle(
                    fontSize: rs.font(20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    Icons.delete_rounded,
                    color: Colors.black,
                    size: rs.font(30),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            thickness: rs.h(0.0015),
          ),

          /// 장바구니 리스트
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: rs.h(0.005),
              ),
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: rs.w(0.015),
                    vertical: rs.h(0.004),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: rs.w(0.01),
                      vertical: rs.h(0.008),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        rs.radius(12),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        /// 상품명
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: rs.font(14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        SizedBox(width: rs.w(0.01)),

                        /// 감소
                        IconButton(
                          onPressed: () {
                            onDecrease(item);
                          },
                          icon: Icon(
                            Icons.remove_circle,
                            size: rs.font(26),
                          ),
                        ),

                        SizedBox(
                          width: rs.w(0.05),
                          child: Center(
                            child: Text(
                              '${item.quantity}개',
                              style: TextStyle(
                                fontSize: rs.font(14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        /// 증가
                        IconButton(
                          onPressed: item.quantity < getStock(item.productId)
                              ? () {
                                  onIncrease(item);
                                }
                              : null,
                          icon: Icon(
                            Icons.add_circle,
                            size: rs.font(26),
                          ),
                        ),

                        SizedBox(width: rs.w(0.01)),

                        /// 가격
                        Text(
                          '${TextUtil.money(item.totalPrice)}원',
                          style: TextStyle(
                            fontSize: rs.font(15),
                            fontWeight: FontWeight.bold,
                            color: PageColors.price,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// 총 금액
          Padding(
            padding: EdgeInsets.all(
              rs.padding(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: rs.w(0.02),
                    vertical: rs.h(0.015),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      rs.radius(16),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '전체 수량',
                              style: TextStyle(
                                fontSize: rs.font(16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${totalValue}개',
                            style: TextStyle(
                              fontSize: rs.font(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: rs.h(0.01)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '총 금액',
                              style: TextStyle(
                                fontSize: rs.font(16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${TextUtil.money(totalPrice)}원',
                            style: TextStyle(
                              fontSize: rs.font(20),
                              fontWeight: FontWeight.bold,
                              color: PageColors.price,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: rs.h(0.02)),
                SizedBox(
                  width: double.infinity,
                  height: rs.h(0.07),
                  child: ElevatedButton(
                    onPressed: onCheckout,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          rs.radius(14),
                        ),
                      ),
                    ),
                    child: Text(
                      '결제하기',
                      style: TextStyle(
                        fontSize: rs.font(20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: rs.h(0.02)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
