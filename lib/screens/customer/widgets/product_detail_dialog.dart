import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/providers/remaining_seconds_provider.dart';
import 'package:kiosk/screens/customer/widgets/product_image_slider.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/kiosk_helper.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';
import 'package:kiosk/providers/user_activity_provider.dart'; // ★ 프로바이더 임포트

class ProductDetailDialog extends ConsumerStatefulWidget {
  final ProductModel product;
  final Function(ProductModel product, int quantity) onAddCart;

  const ProductDetailDialog({
    super.key,
    required this.product,
    required this.onAddCart,
  });

  @override
  ConsumerState<ProductDetailDialog> createState() =>
      _ProductDetailDialogState();
}

class _ProductDetailDialogState extends ConsumerState<ProductDetailDialog> {
  int quantity = 1;
  bool _showStockError = false;

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final product = widget.product;
    final bool isMobile = rs.isMobile || rs.isTablet;
    final remainingSeconds = ref.watch(remainingSecondsProvider);

    return Listener(
      onPointerDown: (_) {
        ref.read(userActivityProvider.notifier).state++;
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // 본래 다이얼로그
          Dialog(
            insetPadding: EdgeInsets.all(rs.padding(16)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(rs.radius(24))),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: isMobile ? rs.w(0.95) : rs.w(0.7),
              height: isMobile ? rs.h(0.85) : rs.h(0.75),
              constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 750),
              child: isMobile
                  ? _buildMobileLayout(context, rs, product)
                  : _buildDesktopLayout(context, rs, product),
            ),
          ),

          // ★ 10초 이하일 때 다이얼로그 최상단 위에 뜨는 카운트다운 경고 배너
          if (remainingSeconds <= 10)
            Positioned(
              top: 10,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.orangeAccent, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '⚠️ $remainingSeconds초 후 화면이 초기화됩니다!',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '화면을 터치하면 계속 주문할 수 있습니다.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
      color: const Color(0xFFF9F9F9),
      child: Center(child: ProductImagesSlider(images: product.images)),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, Responsive rs, ProductModel product) {
    final allProducts = ref.watch(productProvider).value ?? [];
    final bool canAddToCart = !product.isSoldOut && product.stock > 0;

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
                Row(
                  children: [
                    if (product.isSet)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[800],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('세트',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: rs.font(26),
                          fontWeight: FontWeight.w900,
                          fontFamily: 'GmarketSans',
                        ),
                      ),
                    ),
                  ],
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

                // ★ A. 세트 상품일 때: 구성품 및 할인 혜택 카드 노출
                if (product.isSet)
                  _buildSetComponentSection(context, rs, product, allProducts),

                // ★ B. 단품일 때: 이 상품이 포함된 세트 메뉴 추천 배너 노출 (2단계 신규 기능)
                if (!product.isSet)
                  _buildSetRecommendationSection(
                      context, rs, product, allProducts),

                const SizedBox(height: 16),
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
              onPressed: canAddToCart
                  ? () {
                      widget.onAddCart(widget.product, quantity);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: PageColors.cateSelect,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                canAddToCart ? '장바구니 담기' : '품절된 상품입니다',
                style: TextStyle(
                    fontSize: rs.font(18), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ★ [2단계 신규 기능] 단품 선택 시 연관 세트 메뉴 추천 제안 배너 위젯
  Widget _buildSetRecommendationSection(BuildContext context, Responsive rs,
      ProductModel product, List<ProductModel> allProducts) {
    // 현재 단품(product.id)을 구성품으로 포함하고 있는 세트 상품 탐색
    final matchingSets = allProducts
        .where((p) =>
            p.isSet &&
            p.componentIds.contains(product.id) &&
            !p.isSoldOut &&
            p.stock > 0)
        .toList();

    if (matchingSets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: matchingSets.map((setProduct) {
        // 세트 구성품들의 단품 가격 합계 계산
        final components = allProducts
            .where((p) => setProduct.componentIds.contains(p.id))
            .toList();
        final int totalSinglePrice =
            components.fold(0, (sum, comp) => sum + comp.basePrice);
        final int discountAmount = totalSinglePrice - setProduct.basePrice;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade300, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_rounded,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '이 상품이 포함된 세트 메뉴가 있어요!',
                      style: TextStyle(
                        fontSize: rs.font(13),
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                  if (discountAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${TextUtil.money(discountAmount)}원 절약',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: KioskHelper.imageTypeBuilder(
                        setProduct.thumbnail,
                        BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          setProduct.name,
                          style: TextStyle(
                            fontSize: rs.font(14),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '세트 특가 ${TextUtil.money(setProduct.basePrice)}원',
                          style: TextStyle(
                            fontSize: rs.font(12),
                            color: PageColors.price,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // 현재 단품 팝업 닫기
                      showDialog(
                        context: context,
                        builder: (_) => ProductDetailDialog(
                          product: setProduct,
                          onAddCart: widget.onAddCart,
                        ),
                      ); // 세트 상품 팝업 오픈
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('세트 보기', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PageColors.cateSelect,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 세트 구성품 목록 및 할인 혜택 카드 위젯
  Widget _buildSetComponentSection(BuildContext context, Responsive rs,
      ProductModel product, List<ProductModel> allProducts) {
    if (product.componentIds.isEmpty) return const SizedBox.shrink();

    final components =
        allProducts.where((p) => product.componentIds.contains(p.id)).toList();
    final int totalSinglePrice =
        components.fold(0, (sum, item) => sum + item.basePrice);
    final int discountAmount = totalSinglePrice - product.basePrice;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.takeout_dining_rounded,
                  color: Colors.orange, size: 22),
              const SizedBox(width: 8),
              Text(
                '세트 구성품 (${components.length}종)',
                style: TextStyle(
                  fontSize: rs.font(15),
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[900],
                ),
              ),
              const Spacer(),
              if (discountAmount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${TextUtil.money(discountAmount)}원 할인',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: components.map((comp) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: KioskHelper.imageTypeBuilder(
                          comp.thumbnail,
                          BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        comp.name,
                        style: TextStyle(
                          fontSize: rs.font(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '단품 ${TextUtil.money(comp.basePrice)}원',
                      style: TextStyle(
                        fontSize: rs.font(12),
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (discountAmount > 0) ...[
            const Divider(height: 20, color: Colors.amber),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('단품 각각 구매 시',
                    style: TextStyle(
                        fontSize: rs.font(13), color: Colors.grey[700])),
                Text(
                  '${TextUtil.money(totalSinglePrice)}원',
                  style: TextStyle(
                    fontSize: rs.font(14),
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '세트 특가',
                  style: TextStyle(
                    fontSize: rs.font(15),
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[900],
                  ),
                ),
                Text(
                  '${TextUtil.money(product.basePrice)}원',
                  style: TextStyle(
                    fontSize: rs.font(18),
                    fontWeight: FontWeight.w900,
                    color: PageColors.price,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 수량 조절 위젯
  Widget _buildQuantityControl(Responsive rs, ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                          _showStockError = false;
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
