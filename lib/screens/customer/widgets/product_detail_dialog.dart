import 'package:flutter/material.dart';
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
  bool _showStockError = false;

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final product = widget.product;
    final bool isMobile = rs.isMobile || rs.isTablet;

    return Dialog(
      insetPadding: EdgeInsets.all(rs.padding(16)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rs.radius(24))),
      clipBehavior: Clip.antiAlias, // 다이얼로그 모서리 밖으로 컨텐츠 안나가게
      child: Container(
        width: isMobile ? rs.w(0.95) : rs.w(0.7),
        height: isMobile ? rs.h(0.85) : rs.h(0.65),
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 700),
        child: isMobile
            ? _buildMobileLayout(context, rs, product)
            : _buildDesktopLayout(context, rs, product),
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, Responsive rs, ProductModel product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 5, child: _buildImageSection(rs, product)),
        const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        Expanded(flex: 5, child: _buildInfoSection(context, rs, product)),
      ],
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, Responsive rs, ProductModel product) {
    return Column(
      children: [
        Expanded(flex: 4, child: _buildImageSection(rs, product)),
        Expanded(flex: 6, child: _buildInfoSection(context, rs, product)),
      ],
    );
  }

  Widget _buildImageSection(Responsive rs, ProductModel product) {
    return Container(
      color: const Color(0xFFF9F9F9), // 연한 회색 배경
      child: Center(child: ProductImagesSlider(images: product.images)),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, Responsive rs, ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 닫기 버튼
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            padding: const EdgeInsets.all(16),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 28),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상품명
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: rs.font(26),
                    fontWeight: FontWeight.w900,
                    fontFamily: 'GmarketSans',
                  ),
                ),
                const SizedBox(height: 12),
                // 가격
                Text(
                  '${TextUtil.money(product.basePrice)}원',
                  style: TextStyle(
                    fontSize: rs.font(20),
                    color: PageColors.price,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                // 설명
                if (product.description.isNotEmpty)
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: rs.font(14),
                      color: Colors.black54,
                      height: 1.6,
                    ),
                  ),

                const Divider(),
                const SizedBox(height: 16),

                // 태그 정보 (칩 형태)
                _buildTagRow(
                    '장르', product.themes, Colors.blue[50]!, Colors.blue[700]!),
                const SizedBox(height: 8),
                _buildTagRow('종류', product.categories, Colors.green[50]!,
                    Colors.green[700]!),
                const SizedBox(height: 8),
                _buildTagRow('판매자', product.sellers, Colors.orange[50]!,
                    Colors.orange[700]!),

                const SizedBox(height: 12),

                // 수량 조절 섹션
                Text(
                  '구매 수량',
                  style: TextStyle(
                      fontSize: rs.font(16), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildQuantityControl(rs, product),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // 장바구니 담기 버튼 (하단 고정)
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onAddCart(quantity);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PageColors.cateSelect,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                '장바구니 담기',
                style: TextStyle(
                    fontSize: rs.font(18), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 수량 조절 위젯
  Widget _buildQuantityControl(Responsive rs, ProductModel product) {
    return Column(
      // Row를 Column으로 감싸서 아래에 경고 문구 추가
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 재고 부족 경고 문구 (스낵바 대체) ---
        if (_showStockError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              '⚠️ 장바구니 포함 최대 주문 가능 수량은 ${product.stock}개입니다.',
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            // 에러가 있을 때 테두리를 빨간색으로 강조 (선택 사항)
            border: _showStockError
                ? Border.all(color: Colors.redAccent, width: 1.5)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 28,
                onPressed: quantity > 1
                    ? () {
                        setState(() {
                          quantity--;
                          _showStockError = false; // 수량 줄이면 에러 문구 해제
                        });
                      }
                    : null,
                icon: Icon(Icons.remove_circle_outline,
                    color: quantity > 1 ? PageColors.cateSelect : Colors.grey),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$quantity',
                  style: TextStyle(
                      fontSize: rs.font(20), fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                iconSize: 28,
                onPressed: () {
                  if (quantity < product.stock) {
                    setState(() {
                      quantity++;
                      _showStockError = false;
                    });
                  } else {
                    // --- 스낵바 대신 내부 상태를 갱신 ---
                    setState(() {
                      _showStockError = true;
                    });
                  }
                },
                icon: Icon(Icons.add_circle_outline,
                    color: quantity < product.stock
                        ? PageColors.cateSelect
                        : Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 태그 행 위젯
  Widget _buildTagRow(
      String label, List<String> tags, Color bgColor, Color textColor) {
    if (tags.isEmpty) return const SizedBox();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 45,
            child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)))),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(t,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
