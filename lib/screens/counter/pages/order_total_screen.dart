import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';
import 'package:collection/collection.dart';

class OrderTotalScreen extends ConsumerStatefulWidget {
  // 클래스명 변경
  const OrderTotalScreen({super.key});

  @override
  ConsumerState<OrderTotalScreen> createState() => _OrderTotalScreenState();
}

class _OrderTotalScreenState extends ConsumerState<OrderTotalScreen> {
  String _selectedPeriod = '오늘';
  bool _showThemeDistribution = true; // true: 테마별, false: 판매자별

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final orderAsync = ref.watch(orderProvider);
    final productsAsync = ref.watch(productProvider); // 상품 정보 구독 추가

    return Scaffold(
      backgroundColor: baseBackgroundColor[50],
      appBar: AppBar(
        title: const Text('주문 분석 및 통계',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          _buildPeriodChip('오늘'),
          _buildPeriodChip('7일'),
          _buildPeriodChip('한달'),
          const SizedBox(width: 12),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('데이터 로드 실패: $err')),
        data: (orders) {
          final filteredOrders = _getFilteredOrders(orders);
          if (filteredOrders.isEmpty) return _buildEmptyState();

          return productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                _buildBodyContent(filteredOrders, [], rs), // 상품정보 없어도 기본 통계는 표시
            data: (products) => _buildBodyContent(filteredOrders, products, rs),
          );
        },
      ),
    );
  }

  Widget _buildBodyContent(
      List<OrderModel> orders, List<ProductModel> products, Responsive rs) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(rs.padding(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(orders, rs),
          const SizedBox(height: 24),
          rs.isDesktop || rs.isTablet
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _buildTopProductsCard(orders, rs)),
                    const SizedBox(width: 16),
                    Expanded(
                        flex: 4,
                        child: _buildDistributionCard(orders, products, rs)),
                  ],
                )
              : Column(
                  children: [
                    _buildTopProductsCard(orders, rs),
                    const SizedBox(height: 16),
                    _buildDistributionCard(orders, products, rs),
                  ],
                ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // 테마/판매자 분포 분석 카드 (핵심 수정 부분)
  Widget _buildDistributionCard(
      List<OrderModel> orders, List<ProductModel> products, Responsive rs) {
    // 1. 상품 ID별 테마/판매자 맵핑 데이터 생성
    final Map<int, List<String>> themeMap = {
      for (var p in products) p.id: p.themes
    };
    final Map<int, List<String>> sellerMap = {
      for (var p in products) p.id: p.sellers
    };

    // 2. 분포 집계
    final Map<String, int> distribution = {};
    int totalTargetQuantity = 0;

    for (var o in orders) {
      for (var item in o.items) {
        final List<String> targets = _showThemeDistribution
            ? (themeMap[item.productId] ?? ['기타'])
            : (sellerMap[item.productId] ?? ['기타']);

        for (var target in targets) {
          distribution.update(target, (val) => val + item.quantity,
              ifAbsent: () => item.quantity);
          totalTargetQuantity += item.quantity;
        }
      }
    }

    // 상위 5개 추출 및 비율 계산
    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayEntries = sortedEntries.take(5).toList();

    return _buildDashboardSection(
      title: '판매 분포 분석',
      icon: Icons.pie_chart_rounded,
      // 상단 스위치 추가
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSmallToggle('테마', _showThemeDistribution,
              () => setState(() => _showThemeDistribution = true)),
          const SizedBox(width: 4),
          _buildSmallToggle('판매자', !_showThemeDistribution,
              () => setState(() => _showThemeDistribution = false)),
        ],
      ),
      child: Column(
        children: displayEntries.isEmpty
            ? [const Center(child: Text('집계할 데이터가 없습니다.'))]
            : displayEntries.map((e) {
                double percent = totalTargetQuantity > 0
                    ? (e.value / totalTargetQuantity)
                    : 0;
                return _buildCustomProgressBar(e.key, percent,
                    _showThemeDistribution ? Colors.indigo : Colors.teal);
              }).toList(),
      ),
    );
  }

  Widget _buildSmallToggle(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? PageColors.cateSelect : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDashboardSection(
      {required String title,
      required IconData icon,
      required Widget child,
      Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: PageColors.cateSelect, size: 20),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              if (action != null) action,
            ],
          ),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  // --- 데이터 필터링 로직 ---
  List<OrderModel> _getFilteredOrders(List<OrderModel> orders) {
    final now = DateTime.now();
    return orders.where((o) {
      if (o.status != '승인') return false;

      final diff = now.difference(o.createdAt).inDays;
      if (_selectedPeriod == '오늘')
        return diff == 0 && o.createdAt.day == now.day;
      if (_selectedPeriod == '7일') return diff <= 7;
      if (_selectedPeriod == '한달') return diff <= 30;
      return true;
    }).toList();
  }

  // --- UI 컴포넌트들 ---

  Widget _buildPeriodChip(String label) {
    final isSelected = _selectedPeriod == label;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
        selected: isSelected,
        onSelected: (val) =>
            val ? setState(() => _selectedPeriod = label) : null,
        selectedColor: PageColors.cateSelect,
      ),
    );
  }

  Widget _buildSummaryCards(List<OrderModel> orders, Responsive rs) {
    final int totalRevenue = orders.fold(0, (sum, o) => sum + o.totalPrice);
    final int totalCount = orders.length;
    final int avgPrice = totalCount > 0 ? (totalRevenue ~/ totalCount) : 0;

    final int totalItemsSold = orders.fold(
        0,
        (sum, o) =>
            sum + o.items.fold(0, (itemSum, item) => itemSum + item.quantity));

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: rs.isMobile ? 2 : 4,
      childAspectRatio: rs.isMobile ? 1.5 : 1.8,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard('총 매출액', '${TextUtil.money(totalRevenue)}원',
            Icons.payments, Colors.blue),
        _buildStatCard(
            '총 주문건수', '$totalCount건', Icons.receipt_long, Colors.orange),
        _buildStatCard('평균 결제금액', '${TextUtil.money(avgPrice)}원',
            Icons.analytics, Colors.green),
        _buildStatCard(
            '총 판매 수량', '${totalItemsSold}개', Icons.shopping_bag, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  // 많이 팔린 상품 순위
  Widget _buildTopProductsCard(List<OrderModel> orders, Responsive rs) {
    // 상품별 판매량 집계
    final Map<String, int> productSales = {};
    for (var o in orders) {
      for (var item in o.items) {
        productSales.update(item.name, (val) => val + item.quantity,
            ifAbsent: () => item.quantity);
      }
    }
    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topProducts = sortedProducts.take(5).toList();

    return _buildDashboardSection(
      title: '인기 상품 Top 5',
      icon: Icons.star_rounded,
      child: Column(
        children: topProducts.isEmpty
            ? [const Center(child: Text('판매 데이터가 없습니다.'))]
            : topProducts.mapIndexed((index, entry) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index == 0
                        ? Colors.amber
                        : (index == 1 ? Colors.grey[300] : Colors.brown[200]),
                    radius: 14,
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(entry.key,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  trailing: Text('${entry.value}개 판매',
                      style: const TextStyle(
                          color: PageColors.price,
                          fontWeight: FontWeight.w900)),
                );
              }).toList(),
      ),
    );
  }

  Widget _buildCustomProgressBar(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${(percent * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(10)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('해당 기간에 집계된 주문 데이터가 없습니다.'));
  }
}
