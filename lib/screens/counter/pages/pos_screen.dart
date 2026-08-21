import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/kiosk_helper.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';

enum GroupingType { theme, seller, category }

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  List<OrderItemModel> cart = [];
  GroupingType _currentGrouping = GroupingType.theme;

  void _addToCart(ProductModel product) {
    setState(() {
      final index = cart.indexWhere((item) => item.productId == product.id);
      if (index >= 0) {
        cart[index] = cart[index].copyWith(quantity: cart[index].quantity + 1);
      } else {
        cart.add(OrderItemModel(
          productId: product.id,
          name: product.name,
          basePrice: product.basePrice,
          quantity: 1,
        ));
      }
    });
  }

  Future<void> _checkout() async {
    if (cart.isEmpty) return;
    final order = OrderModel(
        items: List.from(cart), createdAt: DateTime.now(), status: '승인');

    await ref.read(orderProvider.notifier).addOrder(order);
    setState(() => cart.clear());
  }

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: rs.isMobile ? 45 : 56, // 앱바 높이 축소
        title: Text('POS 주문',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: rs.isMobile ? 16 : 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildGroupingChip(GroupingType.theme, '테마'),
          _buildGroupingChip(GroupingType.seller, '판매자'),
          _buildGroupingChip(GroupingType.category, '분류'),
          const SizedBox(width: 8),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('에러: $err')),
        data: (products) {
          final Map<String, List<ProductModel>> groupedProducts = {};
          for (var p in products) {
            List<String> targets;
            switch (_currentGrouping) {
              case GroupingType.theme:
                targets = p.themes;
                break;
              case GroupingType.seller:
                targets = p.sellers;
                break;
              case GroupingType.category:
                targets = p.categories;
                break;
            }
            if (targets.isEmpty) {
              groupedProducts.putIfAbsent('기타', () => []).add(p);
            } else {
              for (var target in targets) {
                groupedProducts.putIfAbsent(target, () => []).add(p);
              }
            }
          }
          final sortedKeys = groupedProducts.keys.toList()..sort();

          if (rs.isMobile) {
            return Column(
              children: [
                // 1. 상단 상품 영역 (약 55%)
                Expanded(
                  flex: 55,
                  child: _buildProductList(
                      sortedKeys, groupedProducts, 3), // 3열로 더 촘촘하게
                ),
                // 2. 하단 주문 영역 (약 45% - 절반가량 차지)
                Container(
                  height: MediaQuery.of(context).size.height * 0.45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -4)),
                    ],
                  ),
                  child: _buildOrderPanel(double.infinity, isCompact: true),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                    child: _buildProductList(sortedKeys, groupedProducts, 5)),
                _buildOrderPanel(320),
              ],
            );
          }
        },
      ),
    );
  }

  // 상품 리스트 빌더 (여백 축소)
  Widget _buildProductList(List<String> sortedKeys,
      Map<String, List<ProductModel>> groupedProducts, int crossAxisCount) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final groupName = sortedKeys[index];
        final categoryProducts = groupedProducts[groupName]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(groupName, categoryProducts.length),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.8,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: categoryProducts.length,
              itemBuilder: (context, pIndex) =>
                  _buildPosProductCard(categoryProducts[pIndex]),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // 슬림한 상품 카드
  Widget _buildPosProductCard(ProductModel p) {
    return InkWell(
      onTap: () => _addToCart(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  image: DecorationImage(
                    image: KioskHelper.getImageProvider(p.thumbnail),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${TextUtil.money(p.basePrice)}원',
                          style: const TextStyle(
                              color: PageColors.price,
                              fontSize: 10,
                              fontWeight: FontWeight.w900)),
                      // 재고 상태 표시 (StatusColor 위젯 사용)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              p.stock <= 5 ? Colors.red[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${p.stock}개',
                          style: TextStyle(
                            color: p.stock <= 5 ? Colors.red : Colors.blue[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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

  // 컴팩트 주문 패널
  Widget _buildOrderPanel(double width, {bool isCompact = false}) {
    int totalPrice = cart.fold(0, (sum, item) => sum + item.totalPrice);
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('주문 내역',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('${cart.length}개 상품',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: cart.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cart[index];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(item.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      '${TextUtil.money(item.basePrice)} x ${item.quantity}',
                      style: const TextStyle(fontSize: 11)),
                  trailing: Text(TextUtil.money(item.totalPrice),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  onTap: () => setState(() => item.quantity > 1
                      ? cart[index] = item.copyWith(quantity: item.quantity - 1)
                      : cart.removeAt(index)),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('합계',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(TextUtil.money(totalPrice),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.red)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 42, // 버튼 높이 축소
                  child: ElevatedButton(
                    onPressed: cart.isEmpty ? null : _checkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PageColors.cateSelect,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('주문 완료',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupingChip(GroupingType type, String label) {
    final isSelected = _currentGrouping == type;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 11, color: isSelected ? Colors.white : Colors.black)),
        selected: isSelected,
        onSelected: (val) =>
            val ? setState(() => _currentGrouping = type) : null,
        selectedColor: PageColors.cateSelect,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: PageColors.theme),
          const SizedBox(width: 6),
          Text(title,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text('$count',
              style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        ],
      ),
    );
  }
}
