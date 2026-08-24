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

class _ProductStat {
  int quantity;
  int unitPrice;
  int total;
  _ProductStat(
      {required this.quantity, required this.unitPrice, required this.total});
}

class OrderTotalScreen extends ConsumerStatefulWidget {
  // 클래스명 변경
  const OrderTotalScreen({super.key});

  @override
  ConsumerState<OrderTotalScreen> createState() => _OrderTotalScreenState();
}

class _OrderTotalScreenState extends ConsumerState<OrderTotalScreen> {
  String _selectedPeriod = '오늘';
  bool _showThemeDistribution = true; // true: 테마별, false: 판매자별
  bool _showRevenueDist = true;

  DateTimeRange? _selectedDateRange;

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme:
                const ColorScheme.light(primary: PageColors.cateSelect)),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedPeriod = '사용자설정';
      });
    }
  }

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
          _buildPeriodChip('어제'),
          _buildPeriodChip('7일'),
          _buildPeriodChip('한달'),
          IconButton(
            onPressed: _pickDateRange,
            icon: Icon(Icons.date_range,
                color: _selectedPeriod == '사용자설정' ? Colors.blue : Colors.grey),
          ),
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
    String periodInfo = _selectedPeriod;
    if (_selectedPeriod == '사용자설정' && _selectedDateRange != null) {
      periodInfo =
          "${DateFormat('MM.dd').format(_selectedDateRange!.start)} ~ ${DateFormat('MM.dd').format(_selectedDateRange!.end)}";
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(rs.padding(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text('📊 분석 기간: $periodInfo',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey)),
          ),
          _buildSummaryCards(orders, rs),
          const SizedBox(height: 24),

          // 3. 분포 분석 영역 (수량 기반 vs 매출액 기반 나란히 배치)
          rs.isDesktop || rs.isTablet
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 왼쪽: 수량 기반 분포
                    Expanded(
                        child: _buildDistributionCard(orders, products, rs,
                            isRevenue: false)),
                    const SizedBox(width: 16),
                    // 오른쪽: 매출액 기반 분포
                    Expanded(
                        child: _buildDistributionCard(orders, products, rs,
                            isRevenue: true)),
                  ],
                )
              : Column(
                  children: [
                    _buildDistributionCard(orders, products, rs,
                        isRevenue: false),
                    const SizedBox(height: 16),
                    _buildDistributionCard(orders, products, rs,
                        isRevenue: true),
                  ],
                ),
          const SizedBox(height: 24),

          // 2. 인기 상품 순위 (전체 너비로 확장하여 가독성 강화)
          _buildTopProductsCard(orders, rs),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 테마/판매자 분포 분석 카드 (핵심 수정 부분)
  Widget _buildDistributionCard(
      List<OrderModel> orders, List<ProductModel> products, Responsive rs,
      {required bool isRevenue}) {
    final Map<int, List<String>> themeMap = {
      for (var p in products) p.id: p.themes
    };
    final Map<int, List<String>> sellerMap = {
      for (var p in products) p.id: p.sellers
    };

    // 현재 카드에서 테마를 볼지 판매자를 볼지 결정하는 내부 상태
    final bool currentShowTheme =
        isRevenue ? _showRevenueDist : _showThemeDistribution;

    final Map<String, int> distribution = {};
    int totalValue = 0; // 전체 수량 또는 전체 금액

    for (var o in orders) {
      for (var item in o.items) {
        final List<String> targets = currentShowTheme
            ? (themeMap[item.productId] ?? ['기타'])
            : (sellerMap[item.productId] ?? ['기타']);

        for (var target in targets) {
          // 수량 기반이면 item.quantity를, 매출 기반이면 item.totalPrice를 더함
          final int increment = isRevenue ? item.totalPrice : item.quantity;
          distribution.update(target, (val) => val + increment,
              ifAbsent: () => increment);
          totalValue += increment;
        }
      }
    }

    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayEntries = sortedEntries.take(5).toList();

    return _buildDashboardSection(
      title: isRevenue ? '매출액 분포 분석' : '판매 수량 분포 분석',
      icon: isRevenue ? Icons.monetization_on_rounded : Icons.pie_chart_rounded,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSmallToggle('테마', currentShowTheme, () {
            setState(() => isRevenue
                ? _showRevenueDist = true
                : _showThemeDistribution = true);
          }),
          const SizedBox(width: 4),
          _buildSmallToggle('판매자', !currentShowTheme, () {
            setState(() => isRevenue
                ? _showRevenueDist = false
                : _showThemeDistribution = false);
          }),
        ],
      ),
      child: Column(
        children: displayEntries.isEmpty
            ? [const Center(child: Text('데이터가 없습니다.'))]
            : displayEntries.map((e) {
                double percent = totalValue > 0 ? (e.value / totalValue) : 0;
                String labelSuffix = isRevenue
                    ? ' (${TextUtil.money(e.value)}원)'
                    : ' (${e.value}개)';
                return _buildCustomProgressBar(e.key + labelSuffix, percent,
                    isRevenue ? Colors.deepPurple : Colors.indigo);
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
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return orders.where((o) {
      if (o.status != '승인') return false;

      final orderDate = o.createdAt;
      final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);

      // 사용자 설정 기간
      if (_selectedPeriod == '사용자설정' && _selectedDateRange != null) {
        return orderDate.isAfter(_selectedDateRange!.start
                .subtract(const Duration(seconds: 1))) &&
            orderDate
                .isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }

      // 어제 필터
      if (_selectedPeriod == '어제') return orderDay.isAtSameMomentAs(yesterday);

      // 오늘 필터
      if (_selectedPeriod == '오늘') return orderDay.isAtSameMomentAs(today);

      final diff = now.difference(orderDate).inDays;
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
