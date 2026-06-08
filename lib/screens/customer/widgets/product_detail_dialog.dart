import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/models/product_model.dart';

import 'package:kiosk/screens/customer/widgets/product_image_slider.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';

class ProductDetailDialog extends StatefulWidget {
  final ProductModel product;
  final Function(int quantity) onAddCart;

  const ProductDetailDialog({
    super.key,
    required this.product,
    required this.onAddCart,
  });

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  int quantity = 1;

  List<String> parseImages(String raw) {
    return List<String>.from(jsonDecode(raw));
  }

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);

    final product = widget.product;

    final bool isMobile = rs.isMobile || rs.isTablet;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: rs.padding(16),
        vertical: rs.padding(16),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          rs.radius(20),
        ),
      ),
      child: Container(
        width: isMobile ? rs.w(0.95) : rs.w(0.75),
        height: isMobile ? rs.h(0.92) : rs.h(0.72),
        constraints: const BoxConstraints(
          maxWidth: 1100,
          maxHeight: 750,
        ),
        child: isMobile
            ? _buildMobileLayout(
                context,
                rs,
                product,
              )
            : _buildDesktopLayout(
                context,
                rs,
                product,
              ),
      ),
    );
  }

  /// =========================
  /// 데스크탑 / 태블릿
  /// =========================

  Widget _buildDesktopLayout(
    BuildContext context,
    Responsive rs,
    ProductModel product,
  ) {
    return Row(
      children: [
        /// 이미지 영역
        Expanded(
          flex: 5,
          child: Padding(
            padding: EdgeInsets.all(
              rs.padding(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  rs.radius(16),
                ),
                border: Border.all(
                  width: 1,
                  color: DefaultColors.grey,
                ),
              ),
              child: ProductImagesSlider(
                images: product.images,
              ),
            ),
          ),
        ),

        /// 정보 영역
        Expanded(
          flex: 4,
          child: _buildInfoSection(
            context,
            rs,
            product,
          ),
        ),
      ],
    );
  }

  /// =========================
  /// 모바일
  /// =========================

  Widget _buildMobileLayout(
    BuildContext context,
    Responsive rs,
    ProductModel product,
  ) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: EdgeInsets.all(
              rs.padding(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  rs.radius(16),
                ),
                border: Border.all(
                  width: 1,
                  color: DefaultColors.grey,
                ),
              ),
              child: ProductImagesSlider(
                images: product.images,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: _buildInfoSection(
            context,
            rs,
            product,
          ),
        ),
      ],
    );
  }

  /// =========================
  /// 상품 정보
  /// =========================

  Widget _buildInfoSection(
    BuildContext context,
    Responsive rs,
    ProductModel product,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 닫기 버튼
        Row(
          children: [
            const Spacer(),
            IconButton(
              iconSize: rs.isMobile ? 28 : 34,
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.cancel_outlined,
              ),
            ),
          ],
        ),

        /// 내용
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: rs.padding(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 상품명
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: rs.font(
                      rs.isMobile ? 22 : 28,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: rs.padding(10),
                ),

                /// 가격
                Text(
                  '가격 : ${TextUtil.money(product.basePrice)}원',
                  style: TextStyle(
                    fontSize: rs.font(18),
                    color: PageColors.price,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                /// 재고 부족
                if (product.stock <= 3)
                  Padding(
                    padding: EdgeInsets.only(
                      top: rs.padding(6),
                    ),
                    child: Text(
                      '잔여 ${product.stock}개',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: rs.font(14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                SizedBox(
                  height: rs.padding(16),
                ),

                /// 설명
                if (product.description.isNotEmpty)
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: rs.font(14),
                      height: 1.45,
                    ),
                  ),

                SizedBox(
                  height: rs.padding(16),
                ),

                Divider(
                  height: rs.padding(24),
                ),

                /// 정보
                _buildInfoText(
                  rs,
                  '장르',
                  product.themes.toString(),
                ),

                _buildInfoText(
                  rs,
                  '종류',
                  product.categories.toString(),
                ),

                _buildInfoText(
                  rs,
                  '판매자',
                  product.sellers.toString(),
                ),

                SizedBox(
                  height: rs.padding(24),
                ),

                /// 수량
                Text(
                  '수량',
                  style: TextStyle(
                    fontSize: rs.font(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: rs.padding(10),
                ),

                Row(
                  children: [
                    IconButton(
                      iconSize: rs.isMobile ? 30 : 36,
                      onPressed: quantity > 1
                          ? () {
                              setState(() {
                                quantity--;
                              });
                            }
                          : null,
                      icon: const Icon(
                        Icons.remove_circle,
                      ),
                    ),
                    SizedBox(
                      width: rs.padding(12),
                    ),
                    Text(
                      '$quantity',
                      style: TextStyle(
                        fontSize: rs.font(22),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: rs.padding(12),
                    ),
                    IconButton(
                      iconSize: rs.isMobile ? 30 : 36,
                      onPressed: quantity < product.stock
                          ? () {
                              setState(() {
                                quantity++;
                              });
                            }
                          : null,
                      icon: const Icon(
                        Icons.add_circle,
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: rs.padding(20),
                ),
              ],
            ),
          ),
        ),

        /// 장바구니 버튼
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: rs.padding(16),
            vertical: rs.padding(12),
          ),
          child: SizedBox(
            width: double.infinity,
            height: rs.isMobile ? 52 : 60,
            child: ElevatedButton(
              onPressed: () {
                widget.onAddCart(quantity);

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: iconThemeColor.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    rs.radius(14),
                  ),
                ),
              ),
              child: Text(
                '장바구니 담기',
                style: TextStyle(
                  fontSize: rs.font(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoText(
    Responsive rs,
    String title,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: rs.padding(6),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: rs.font(12),
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: '$title : ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value,
            ),
          ],
        ),
      ),
    );
  }
}
