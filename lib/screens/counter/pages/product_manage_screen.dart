// lib/screens/counter/pages/product_manage_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/dao_provider.dart';
import 'package:kiosk/providers/pos_network_service_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/providers/settings_provider.dart';
import 'package:kiosk/screens/counter/widgets/product_add_dialog.dart';
import 'package:kiosk/screens/counter/widgets/product_info_detail_dialog.dart';
import 'package:kiosk/screens/counter/widgets/product_set_add_dialog.dart';
import 'package:kiosk/screens/customer/widgets/category_render_dialog.dart';
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
  GroupingType _currentGrouping = GroupingType.theme;
  bool _isSelectionMode = false;
  bool _isReorderMode = false;

  final Set<ProductModel> _selectedProducts = {};
  List<ProductModel> _reorderList = []; // 순서 변경용 드래그 리스트

  List<String> sortTagsByMasterOrder(
      List<String> tags, List<String> masterOrder) {
    final list = List<String>.from(tags);
    list.sort((a, b) {
      int indexA = masterOrder.indexOf(a);
      int indexB = masterOrder.indexOf(b);
      if (indexA == -1) indexA = 999;
      if (indexB == -1) indexB = 999;
      return indexA.compareTo(indexB);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);
    final posNetwork = ref.watch(posNetworkServiceProvider);
    final rs = Responsive(context);
    final settings = ref.watch(settingsProvider);

    int crossAxisCount = settings.productManageGridCount > 0
        ? settings.productManageGridCount
        : (rs.isMobile ? 3 : 7);
    if (rs.isMobile) {
      crossAxisCount = crossAxisCount.clamp(3, 5);
    } else {
      crossAxisCount = crossAxisCount.clamp(5, 10);
    }

    return Scaffold(
      backgroundColor: baseBackgroundColor[50],
      appBar: AppBar(
        title: Text(_isReorderMode ? '상품 순서 변경 모드' : '상품 관리'),
        actions: [
          // -------------------------------------------------------------
          // 모드 1: 순서 변경 모드일 때 액션 버튼
          // -------------------------------------------------------------
          if (_isReorderMode) ...[
            ElevatedButton.icon(
              onPressed: () async {
                await ref
                    .read(productProvider.notifier)
                    .updateProductOrders(_reorderList);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('상품 순서가 저장 및 동기화되었습니다.')),
                  );
                }
                setState(() => _isReorderMode = false);
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('순서 저장'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => _isReorderMode = false),
              child:
                  const Text('취소', style: TextStyle(color: Colors.redAccent)),
            ),
          ]

          // -------------------------------------------------------------
          // 모드 2: 세트 구성 선택 모드일 때 액션 버튼
          // -------------------------------------------------------------
          else if (_isSelectionMode) ...[
            Center(
              child: Text(
                '${_selectedProducts.length}개 선택됨',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: PageColors.price),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _selectedProducts.length >= 2
                  ? _openCreateSetDialog
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('세트를 구성하려면 2개 이상의 상품을 선택하세요.')),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PageColors.cateSelect,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('구성 완료'),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedProducts.clear();
              }),
              child:
                  const Text('취소', style: TextStyle(color: Colors.redAccent)),
            ),
          ]

          // -------------------------------------------------------------
          // 모드 3: 일반 모드 (등록, 세트, 동기화 3개 주요 버튼 외부 노출)
          // -------------------------------------------------------------
          else ...[
            // 1. [+ 상품 등록] 버튼
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => const ProductAddDialog());
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(rs.isMobile ? '등록' : '상품 등록'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PageColors.cateSelect,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                    horizontal: rs.padding(10), vertical: rs.padding(8)),
              ),
            ),
            const SizedBox(width: 6),

            // 2. [세트 구성] 버튼
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                  _selectedProducts.clear();
                });
              },
              icon: const Icon(Icons.library_add_rounded, size: 16),
              label: Text(rs.isMobile ? '세트' : '세트 구성'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PageColors.cateSelect,
                side:
                    const BorderSide(color: PageColors.cateSelect, width: 1.2),
                padding: EdgeInsets.symmetric(
                    horizontal: rs.padding(8), vertical: rs.padding(8)),
              ),
            ),
            const SizedBox(width: 6),

            // ★ 3. [전체 동기화] 버튼 (외부 노출)
            if (posNetwork.status == PosBroadcastStatus.broadcasting)
              OutlinedButton.icon(
                onPressed: _showSyncConfirmDialog,
                icon: const Icon(Icons.sync_rounded,
                    size: 16, color: PageColors.cateSelect),
                label: Text(rs.isMobile ? '동기화' : '전체 동기화'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PageColors.cateSelect,
                  side: const BorderSide(
                      color: PageColors.cateSelect, width: 1.2),
                  padding: EdgeInsets.symmetric(
                      horizontal: rs.padding(8), vertical: rs.padding(8)),
                ),
              ),
            const SizedBox(width: 4),

            // 4. [⋮ 더보기] 팝업 통합 메뉴 (정렬 및 화면 설정)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: '추가 관리 메뉴',
              onSelected: (value) async {
                switch (value) {
                  case 'reorder_products':
                    final currentProducts =
                        ref.read(productProvider).value ?? [];
                    setState(() {
                      _reorderList = List.from(currentProducts);
                      _isReorderMode = true;
                      _isSelectionMode = false;
                    });
                    break;
                  case 'reorder_categories':
                    showDialog(
                      context: context,
                      builder: (context) => const CategoryReorderDialog(),
                    );
                    break;
                  case 'screen_settings':
                    _showSettingsDialog(rs);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reorder_products',
                  child: Row(
                    children: [
                      Icon(Icons.swap_vert_rounded,
                          size: 20, color: Colors.black87),
                      SizedBox(width: 12),
                      Text('상품 순서 변경'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reorder_categories',
                  child: Row(
                    children: [
                      Icon(Icons.category_outlined,
                          size: 20, color: Colors.black87),
                      SizedBox(width: 12),
                      Text('분류/테마 순서 변경'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'screen_settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_suggest_rounded,
                          size: 20, color: Colors.black87),
                      SizedBox(width: 12),
                      Text('화면 표시 설정'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: 8),
        ],
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

          if (_isReorderMode) {
            return _buildReorderView();
          }

          final masterThemes = ref.watch(orderedThemesProvider).value ?? [];
          final masterCategories =
              ref.watch(orderedCategoriesProvider).value ?? [];
          final masterSellers = ref.watch(orderedSellersProvider).value ?? [];

          List<String> currentMasterList = [];
          switch (_currentGrouping) {
            case GroupingType.theme:
              currentMasterList = masterThemes;
              break;
            case GroupingType.seller:
              currentMasterList = masterSellers;
              break;
            case GroupingType.category:
              currentMasterList = masterCategories;
              break;
          }

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

          final sortedKeys = sortTagsByMasterOrder(
              groupedProducts.keys.toList(), currentMasterList);

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

  /// 순서 직접 이동 메서드
  void _jumpToPosition(int currentIndex, int targetPosition1Based) {
    final targetIndex =
        (targetPosition1Based - 1).clamp(0, _reorderList.length - 1);
    if (currentIndex == targetIndex) return;

    setState(() {
      final item = _reorderList.removeAt(currentIndex);
      _reorderList.insert(targetIndex, item);
    });
  }

  /// 맨 위로 이동
  void _moveToTop(int currentIndex) {
    if (currentIndex == 0) return;
    setState(() {
      final item = _reorderList.removeAt(currentIndex);
      _reorderList.insert(0, item);
    });
  }

  /// 맨 아래로 이동
  void _moveToBottom(int currentIndex) {
    if (currentIndex == _reorderList.length - 1) return;
    setState(() {
      final item = _reorderList.removeAt(currentIndex);
      _reorderList.add(item);
    });
  }

  /// 순서 번호 클릭 시 숫자 직접 입력 다이얼로그
  void _showJumpToPositionDialog(int currentIndex) {
    final controller = TextEditingController(text: '${currentIndex + 1}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('[${_reorderList[currentIndex].name}] 순서 변경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 위치: #${currentIndex + 1} / 전체 ${_reorderList.length}개',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '이동할 순서 번호 입력 (1~${_reorderList.length})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null) {
                _jumpToPosition(currentIndex, parsed);
              }
              Navigator.pop(context);
            },
            child: const Text('이동'),
          ),
        ],
      ),
    );
  }

  /// 드래그 앤 드롭 + 숫자 입력 + 퀵 이동 버튼 병행 UI
  Widget _buildReorderView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '💡 [ #순서 ] 클릭하여 숫자 직접 입력, [ ⤒ / ⤓ ] 퀵 이동, 또는 우측 (≡) 드래그를 병행하여 순서를 조절하세요.',
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ReorderableListView.builder(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _reorderList.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _reorderList.removeAt(oldIndex);
                  _reorderList.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final product = _reorderList[index];
                return Card(
                  key: ValueKey(product.id),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _showJumpToPositionDialog(index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: PageColors.cateSelect.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: PageColors.cateSelect, width: 1.2),
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                color: PageColors.cateSelect,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: KioskHelper.imageTypeBuilder(
                              product.thumbnail,
                              BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${TextUtil.money(product.basePrice)}원 | 재고 ${product.stock}개',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.vertical_align_top_rounded,
                              size: 20),
                          color: index == 0 ? Colors.grey[300] : Colors.blue,
                          tooltip: '맨 위로 이동',
                          onPressed:
                              index == 0 ? null : () => _moveToTop(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.vertical_align_bottom_rounded,
                              size: 20),
                          color: index == _reorderList.length - 1
                              ? Colors.grey[300]
                              : Colors.orange,
                          tooltip: '맨 아래로 이동',
                          onPressed: index == _reorderList.length - 1
                              ? null
                              : () => _moveToBottom(index),
                        ),
                        const SizedBox(width: 4),
                        ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.drag_handle_rounded,
                                color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
                    .updateProductManageGridCount(current);
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
    final isSelected = _selectedProducts.contains(product);

    return Material(
      color: isSelected ? Colors.blue[50] : Colors.white,
      borderRadius: BorderRadius.circular(rs.radius(8)),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedProducts.remove(product);
              } else {
                _selectedProducts.add(product);
              }
            });
          } else {
            showDialog(
                context: context,
                builder: (context) =>
                    ProductInfoDetailDialog(product: product));
          }
        },
        child: Stack(
          children: [
            Column(
              children: [
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
                              color:
                                  (isLowStock ? Colors.red : Colors.blue[700])!
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
                              fontWeight: FontWeight.bold,
                              fontSize: rs.font(13)),
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
            if (_isSelectionMode)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PageColors.cateSelect
                        : Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: PageColors.cateSelect, width: 1.5),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 18,
                    color: isSelected ? Colors.white : Colors.transparent,
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

  void _openCreateSetDialog() {
    if (_selectedProducts.isEmpty) return;
    final List<ProductModel> componentsSnapshot = _selectedProducts.toList();
    showDialog(
      context: context,
      builder: (context) => ProductSetAddDialog(
        components: componentsSnapshot,
      ),
    );
    setState(() {
      _isSelectionMode = false;
      _selectedProducts.clear();
    });
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
