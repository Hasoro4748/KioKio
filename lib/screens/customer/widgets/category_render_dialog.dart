// lib/screens/counter/widgets/category_reorder_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/providers/dao_provider.dart';
import 'package:kiosk/providers/pos_network_service_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/theme/common_theme.dart';

class CategoryReorderDialog extends ConsumerStatefulWidget {
  const CategoryReorderDialog({super.key});

  @override
  ConsumerState<CategoryReorderDialog> createState() =>
      _CategoryReorderDialogState();
}

class _CategoryReorderDialogState extends ConsumerState<CategoryReorderDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _themes = [];
  List<String> _sellers = [];
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final filterDao = ref.read(filterDaoProvider);
    final themes = await filterDao.getThemes();
    final sellers = await filterDao.getSellers();
    final categories = await filterDao.getCategories();

    setState(() {
      _themes = List.from(themes);
      _sellers = List.from(sellers);
      _categories = List.from(categories);
      _isLoading = false;
    });
  }

  Future<void> _saveOrders() async {
    final filterDao = ref.read(filterDaoProvider);
    await filterDao.updateThemeOrders(_themes);
    await filterDao.updateSellerOrders(_sellers);
    await filterDao.updateCategoryOrders(_categories);

    // ★ 마스터 정렬 프로바이더 갱신
    ref.invalidate(orderedThemesProvider);
    ref.invalidate(orderedSellersProvider);
    ref.invalidate(orderedCategoriesProvider);

    // 전체 동기화 및 화면 갱신
    ref.read(productProvider.notifier).reload();
    ref.read(posNetworkServiceProvider.notifier).syncAllProducts();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('분류/테마 순서가 저장 및 동기화되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('분류 / 테마 순서 변경'),
      content: SizedBox(
        width: 450,
        height: 500,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: PageColors.cateSelect,
              indicatorColor: PageColors.cateSelect,
              tabs: const [
                Tab(text: '테마'),
                Tab(text: '판매자'),
                Tab(text: '카테고리'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReorderList(_themes),
                        _buildReorderList(_sellers),
                        _buildReorderList(_categories),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소')),
        ElevatedButton(
            onPressed: _saveOrders, child: const Text('순서 저장 및 동기화')),
      ],
    );
  }

  Widget _buildReorderList(List<String> items) {
    if (items.isEmpty) {
      return const Center(child: Text('등록된 항목이 없습니다.'));
    }
    return ReorderableListView.builder(
      physics: const ClampingScrollPhysics(), // ★ 스크롤 바운싱 어서션 에러 방지
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final name = items[index];
        return Container(
          key: ValueKey(name),
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ListTile(
            dense: true, // ★ 높이를 슬림하게 조절하여 어서션 방지
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: PageColors.buttonBack,
              child: Text(
                '#${index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  color: PageColors.textBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            trailing: const Icon(Icons.drag_handle_rounded,
                color: Colors.grey, size: 20),
          ),
        );
      },
    );
  }
}
