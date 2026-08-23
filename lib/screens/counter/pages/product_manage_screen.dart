import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/pos_network_service_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/providers/settings_provider.dart';
import 'package:kiosk/screens/counter/widgets/product_add_dialog.dart';
import 'package:kiosk/screens/counter/widgets/product_info_detail_dialog.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/kiosk_helper.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';
import 'package:kiosk/network/pos_network_status.dart';

enum GroupingType { theme, seller, category }

class ProductManageScreen extends ConsumerStatefulWidget {
  const ProductManageScreen({super.key});

  @override
  ConsumerState<ProductManageScreen> createState() =>
      _ProductManageScreenState();
}

class _ProductManageScreenState extends ConsumerState<ProductManageScreen> {
  GroupingType _currentGrouping = GroupingType.category;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);
    final posNetwork = ref.watch(posNetworkServiceProvider);
    final rs = Responsive(context);
    final settings = ref.watch(settingsProvider);

    // 기기별 기본값 및 제한 적용
    int crossAxisCount = settings.productManageGridCount > 0
        ? settings.productManageGridCount
        : (rs.isMobile ? 3 : 7);
    // 강제 제한 (혹시 모를 설정 오류 방지)
    if (rs.isMobile) {
      crossAxisCount = crossAxisCount.clamp(3, 5);
    } else {
      crossAxisCount = crossAxisCount.clamp(5, 10);
    }
    return Scaffold(
      backgroundColor: baseBackgroundColor[50],
      appBar: AppBar(
        title: const Text('상품 관리'),
        actions: [
          if (posNetwork.status == PosBroadcastStatus.broadcasting)
            IconButton(
              onPressed: () => _showSyncConfirmDialog(),
              icon:
                  const Icon(Icons.sync_rounded, color: PageColors.cateSelect),
              tooltip: '전체 동기화',
            ),
          IconButton(
            onPressed: () => _showSettingsDialog(rs), // 설정 다이얼로그 호출
            icon: const Icon(Icons.settings_suggest_rounded),
            tooltip: '화면 설정',
          ),
          IconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => const ProductAddDialog());
            },
            icon: const Icon(Icons.add_box_rounded),
          ),
          const SizedBox(width: 8),
        ],
        // AppBar 아래에 필터 바 배치
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sort_rounded, size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                _buildGroupingChip(GroupingType.theme, '테마별'),
                _buildGroupingChip(GroupingType.seller, '판매자별'),
                _buildGroupingChip(GroupingType.category, '분류별'),
              ],
            ),
          ),
        ),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('상품을 불러오지 못했습니다.\n$error')),
        data: (products) {
          if (products.isEmpty) return _buildEmptyState(rs);

          // 데이터 그룹화 (기존 로직 유지)
          final Map<String, List<ProductModel>> groupedProducts = {};
          for (var p in products) {
            List<String> targets = [];
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
              groupedProducts.putIfAbsent('미지정', () => []).add(p);
            } else {
              for (var target in targets) {
                groupedProducts.putIfAbsent(target, () => []).add(p);
              }
            }
          }
          final sortedKeys = groupedProducts.keys.toList()..sort();

          return ListView.builder(
            padding: EdgeInsets.all(rs.padding(8)),
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
                    itemCount: categoryProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      // 텍스트 영역을 위해 세로 비율을 충분히(0.72) 확보합니다.
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, pIndex) =>
                        _buildProductGridItem(categoryProducts[pIndex], rs),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // 화면 설정 다이얼로그
  void _showSettingsDialog(Responsive rs) {
    final savedCount = ref.read(settingsProvider).productManageGridCount;
    double min = rs.isMobile ? 3 : 5;
    double max = rs.isMobile ? 5 : 10;
    int current = (savedCount > 0 ? savedCount : (rs.isMobile ? 3 : 7))
        .clamp(min.toInt(), max.toInt());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('화면 표시 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  '${rs.isMobile ? "모바일" : "태블릿/PC"} 최적화 범위: ${min.toInt()}~${max.toInt()}개'),
              Slider(
                value: current.toDouble(),
                min: min,
                max: max,
                divisions: (max - min).toInt(),
                label: '$current개',
                onChanged: (value) =>
                    setDialogState(() => current = value.toInt()),
              ),
              Text('한 줄에 $current개씩 표시',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .updateProductGridCount(current);
                Navigator.pop(context);
              },
              child: const Text('적용'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupingChip(GroupingType type, String label) {
    final isSelected = _currentGrouping == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        onSelected: (val) =>
            val ? setState(() => _currentGrouping = type) : null,
        selectedColor: PageColors.cateSelect,
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // 섹션 헤더 (그룹 이름)
  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Container(width: 4, height: 18, color: PageColors.cateSelect),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text('($count)',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProductGridItem(ProductModel product, Responsive rs) {
    final isLowStock = product.stock <= 5;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: () => showDialog(
            context: context,
            builder: (context) => ProductInfoDetailDialog(product: product)),
        child: Column(
          children: [
            // 1. 이미지 영역 (Flex를 주어 가변 대응)
            Expanded(
              flex: 65,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  KioskHelper.imageTypeBuilder(
                      product.images.firstOrNull?.imagePath ?? '',
                      BoxFit.cover),
                  if (!product.isAvailable)
                    Container(
                        color: Colors.black54,
                        child: const Center(
                            child: Text('비활성화',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))))
                  else if (product.isSoldOut)
                    Container(
                        color: Colors.black54,
                        child: const Center(
                            child: Text('품절',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)))),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                          color: (isLowStock ? Colors.red : Colors.blue[700])!
                              .withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('${product.stock}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            // 2. 텍스트 영역 (Flex를 주어 고정 비율 유지)
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: rs.font(13)),
                    ),
                    Text(
                      '${TextUtil.money(product.basePrice)}원',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: PageColors.price,
                          fontWeight: FontWeight.w700,
                          fontSize: rs.font(12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Responsive rs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('등록된 상품이 없습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  void _showSyncConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('전체 동기화'),
          ],
        ),
        content: const Text('연결된 모든 키오스크의 데이터를 POS의 최신 정보로 덮어씌웁니다. 진행하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              ref.read(posNetworkServiceProvider.notifier).syncAllProducts();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('동기화 명령을 전송했습니다.')));
            },
            child: const Text('동기화 시작'),
          ),
        ],
      ),
    );
  }
}
