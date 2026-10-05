import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiosk/models/product_image_model.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/dao_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ProductSetAddDialog extends ConsumerStatefulWidget {
  final List<ProductModel> components; // 선택된 원본 상품들

  const ProductSetAddDialog({super.key, required this.components});

  @override
  ConsumerState<ProductSetAddDialog> createState() =>
      _ProductSetAddDialogState();
}

class _ProductSetAddDialogState extends ConsumerState<ProductSetAddDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  final List<String> _localNewThemes = [];
  final List<String> _localNewSellers = [];
  final List<String> _localNewCategories = [];

  final List<dynamic> _images = []; // ProductImageModel(기존) 또는 File(신규)
  final ImagePicker _picker = ImagePicker();

  late List<String> _selectedThemes;
  late List<String> _selectedSellers;
  late List<String> _selectedCategories;

  @override
  void initState() {
    super.initState();

    int totalBasePrice =
        widget.components.fold(0, (sum, p) => sum + p.basePrice);

    _nameController = TextEditingController(
        text: "${widget.components.map((e) => e.name).join(' + ')} 세트");
    _priceController =
        TextEditingController(text: (totalBasePrice).toInt().toString());
    _descController = TextEditingController(
        text: "구성품: ${widget.components.map((e) => e.name).join(', ')}");

    _selectedThemes =
        widget.components.expand((p) => p.themes).toSet().toList();
    _selectedSellers =
        widget.components.expand((p) => p.sellers).toSet().toList();
    _selectedCategories =
        widget.components.expand((p) => p.categories).toSet().toList();

    for (var p in widget.components) {
      if (p.images.isNotEmpty) {
        _images.add(p.images.first);
      }
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _images.addAll(images.map((e) => File(e.path))));
    }
  }

  Future<void> _saveSetProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final appDir = await getApplicationDocumentsDirectory();
    final productDir = Directory(p.join(appDir.path, 'product_images'));
    if (!await productDir.exists()) await productDir.create();

    // 이미지 파일 처리
    List<ProductImageModel> finalImageModels = [];
    for (int i = 0; i < _images.length; i++) {
      final img = _images[i];
      if (img is ProductImageModel) {
        finalImageModels.add(img.copyWith(sortOrder: i, isThumbnail: i == 0));
      } else if (img is File) {
        final fileName =
            '${DateTime.now().microsecondsSinceEpoch}_${p.basename(img.path)}';
        final localPath = p.join(productDir.path, fileName);
        await img.copy(localPath);
        finalImageModels.add(ProductImageModel(
          id: 0,
          productId: 0,
          imagePath: localPath,
          isThumbnail: i == 0,
          sortOrder: i,
          createdAt: DateTime.now(),
        ));
      }
    }

    final newSet = ProductModel(
      id: 0,
      name: _nameController.text,
      basePrice: int.parse(_priceController.text),
      stock: 0, // 세트는 실시간 계산하므로 0
      description: _descController.text,
      images: finalImageModels,
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      themes: _selectedThemes,
      sellers: _selectedSellers,
      categories: _selectedCategories,
      isSet: true, // 세트 상품 마크
      componentIds: widget.components.map((e) => e.id).toList(), // 구성품 ID 저장
    );

    await ref.read(productProvider.notifier).addProduct(newSet);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filterDao = ref.watch(filterDaoProvider); // DAO 접근

    return AlertDialog(
      title: const Text('신규 세트 상품 구성'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildImageSection(),
                const SizedBox(height: 20),
                TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: '세트 명칭', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                        labelText: '세트 판매 가격',
                        border: OutlineInputBorder(),
                        suffixText: '원'),
                    keyboardType: TextInputType.number),

                const Divider(height: 40),
                Text(
                  '세트 구성 : ${widget.components.length}개',
                ),

                // --- 3. 태그 관리 섹션 추가 (구성품 데이터가 이미 삽입된 상태) ---
                _buildManageableSection('테마', filterDao.getThemes(),
                    _selectedThemes, Icons.palette_outlined),
                _buildManageableSection('판매자', filterDao.getSellers(),
                    _selectedSellers, Icons.storefront_outlined),
                _buildManageableSection('카테고리', filterDao.getCategories(),
                    _selectedCategories, Icons.category_outlined),

                const Divider(height: 40),
                TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                        labelText: '세트 상세 설명', border: OutlineInputBorder()),
                    maxLines: 3),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소')),
        ElevatedButton(
            onPressed: _saveSetProduct, child: const Text('세트 저장 및 동기화')),
      ],
    );
  }

  // --- 헬퍼 메서드: ProductAddDialog의 로직과 동일하게 구현 ---
  Widget _buildManageableSection(String title, Future<List<String>> future,
      List<String> selectedList, IconData icon) {
    return FutureBuilder<List<String>>(
      future: future,
      builder: (context, snapshot) {
        final options = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: PageColors.cateSelect),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                TextButton(
                  onPressed: () => _showAddTagDialog(title, selectedList),
                  child: const Text('+ 직접입력', style: TextStyle(fontSize: 12)),
                )
              ],
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                  isDense: true, border: OutlineInputBorder()),
              items: options
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null && !selectedList.contains(v))
                  setState(() => selectedList.add(v));
              },
              hint: Text('$title 선택 (이미 ${selectedList.length}개 선택됨)'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: selectedList
                  .map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        onDeleted: () => setState(() => selectedList.remove(s)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: PageColors.buttonBack,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showAddTagDialog(String title, List<String> selectedList) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('새 $title 입력'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty)
                  setState(() => selectedList.add(controller.text.trim()));
                Navigator.pop(context);
              },
              child: const Text('추가')),
        ],
      ),
    );
  }

  // 이미지 미리보기 UI
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('세트 이미지 (구성품 이미지가 자동 등록됩니다)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + 1,
            itemBuilder: (context, index) {
              // (+) 버튼 로직
              if (index == _images.length) {
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add_a_photo)),
                );
              }

              // 이미지 렌더링 로직 (ProductImageModel 또는 File 객체 대응)
              final img = _images[index];
              return Stack(
                children: [
                  Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                          image: img is ProductImageModel
                              ? FileImage(File(img.imagePath))
                              : FileImage(img as File),
                          fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(index)),
                      child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child:
                              Icon(Icons.close, size: 12, color: Colors.white)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
