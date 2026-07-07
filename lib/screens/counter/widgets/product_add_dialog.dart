import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiosk/models/product_image_model.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/dao_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/providers/product_service_provider.dart';
import 'package:kiosk/providers/repository_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ProductAddDialog extends ConsumerStatefulWidget {
  const ProductAddDialog({super.key});

  @override
  ConsumerState<ProductAddDialog> createState() => _ProductAddDialogState();
}

final themesProvider =
    FutureProvider((ref) => ref.watch(filterDaoProvider).getThemes());
final sellersProvider =
    FutureProvider((ref) => ref.watch(filterDaoProvider).getSellers());
final categoriesProvider =
    FutureProvider((ref) => ref.watch(filterDaoProvider).getCategories());

class _ProductAddDialogState extends ConsumerState<ProductAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();

  final _newThemeController = TextEditingController();
  final _newSellerController = TextEditingController();
  final _newCategoryController = TextEditingController();

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  List<String> _selectedThemes = [];
  List<String> _selectedSellers = [];
  List<String> _selectedCategories = [];

  final List<String> _localNewThemes = [];
  final List<String> _localNewSellers = [];
  final List<String> _localNewCategories = [];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _newThemeController.dispose();
    _newSellerController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  /// 이미지 선택 및 로컬 저장소 복사 로직
  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  /// 새로운 카테고리 추가
  void _addNewItem(String value, List<String> availableList,
      List<String> selectedList, TextEditingController controller) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      if (!availableList.contains(trimmed)) {
        availableList.add(trimmed);
      }
      if (!selectedList.contains(trimmed)) {
        selectedList.add(trimmed);
      }
      controller.clear();
    });
  }

  /// 상품 저장 로직
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. 로컬 저장소 경로 확보
    final appDir = await getApplicationDocumentsDirectory();
    final productDir = Directory(p.join(appDir.path, 'product_images'));
    if (!await productDir.exists()) await productDir.create();

    // 2. 이미지 파일들을 앱 내부 저장소로 복사
    List<ProductImageModel> imageModels = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      final file = _selectedImages[i];
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final localPath = p.join(productDir.path, fileName);

      await file.copy(localPath); // 파일 복사

      imageModels.add(ProductImageModel(
        id: 0,
        productId: 0,
        imagePath: localPath,
        isThumbnail: i == 0, // 첫 번째 이미지를 썸네일로 설정
        sortOrder: i, createdAt: DateTime.now(),
      ));
    }

    // 3. 모델 생성
    final newProduct = ProductModel(
      id: 0,
      name: _nameController.text,
      basePrice: int.parse(_priceController.text),
      stock: int.parse(_stockController.text),
      description: _descController.text,
      images: imageModels,
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      themes: _selectedThemes,
      sellers: _selectedSellers,
      categories: _selectedCategories,
    );

    // 4. DB 저장 및 새로고침
    await ref.read(productProvider.notifier).addProduct(newProduct);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filterDao = ref.watch(filterDaoProvider);

    return AlertDialog(
      title: const Text('새 상품 등록'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 이미지 선택 영역
                _buildImagePickerSection(),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: '상품명', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? '이름을 입력하세요' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                            labelText: '가격', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? '가격을 입력하세요' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                            labelText: '초기 재고', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? '재고를 입력하세요' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // --- 테마 섹션 (FutureBuilder 사용) ---
                FutureBuilder<List<String>>(
                  future: filterDao.getThemes(),
                  builder: (context, snapshot) {
                    return _buildManageableChoiceSection(
                      title: '테마',
                      // snapshot.data가 로드될 때까지 빈 리스트 전달
                      availableItems: snapshot.data ?? [],
                      localNewItems: _localNewThemes,
                      selectedList: _selectedThemes,
                      onAdd: (val) =>
                          _onItemAdd(val, _localNewThemes, _selectedThemes),
                    );
                  },
                ),

                // --- 판매자 섹션 ---
                FutureBuilder<List<String>>(
                  future: filterDao.getSellers(),
                  builder: (context, snapshot) {
                    return _buildManageableChoiceSection(
                      title: '판매자',
                      availableItems: snapshot.data ?? [],
                      localNewItems: _localNewSellers,
                      selectedList: _selectedSellers,
                      onAdd: (val) =>
                          _onItemAdd(val, _localNewSellers, _selectedSellers),
                    );
                  },
                ),

                // --- 카테고리 섹션 ---
                FutureBuilder<List<String>>(
                  future: filterDao.getCategories(),
                  builder: (context, snapshot) {
                    return _buildManageableChoiceSection(
                      title: '카테고리',
                      availableItems: snapshot.data ?? [],
                      localNewItems: _localNewCategories,
                      selectedList: _selectedCategories,
                      onAdd: (val) => _onItemAdd(
                          val, _localNewCategories, _selectedCategories),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                      labelText: '상품 설명', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소')),
        ElevatedButton(onPressed: _saveProduct, child: const Text('등록하기')),
      ],
    );
  }

  // --- 헬퍼 메서드 추가: _onItemAdd ---
  void _onItemAdd(
      String value, List<String> localList, List<String> selectedList) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      if (!selectedList.contains(trimmed)) {
        selectedList.add(trimmed);
        if (!localList.contains(trimmed)) {
          localList.add(trimmed);
        }
      }
    });
  }

  Widget _buildManageableChoiceSection({
    required String title,
    required List<String> availableItems, // AsyncValue 대신 일반 리스트
    required List<String> localNewItems,
    required List<String> selectedList,
    required Function(String) onAdd,
  }) {
    final List<String> options = [
      ...availableItems,
      ...localNewItems,
    ].toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),

        // 1. 드롭다운 + 직접 입력 영역
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: '$title 선택 또는 입력',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: const OutlineInputBorder(),
                ),
                // 드롭다운 목록 (기존 옵션들)
                items: options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onAdd(newValue); // 선택 시 리스트에 추가
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // 직접 입력을 위한 버튼 (필요 시 텍스트 필드로 전환 가능)
            IconButton.outlined(
              onPressed: () {
                _showAddCustomDialog(title, onAdd);
              },
              icon: const Icon(Icons.edit_note),
              tooltip: '직접 입력',
            ),
          ],
        ),

        // 2. 선택된 항목 표시 영역 (Chip 목록)
        if (selectedList.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: selectedList.map((item) {
              return Chip(
                label: Text(item, style: const TextStyle(fontSize: 12)),
                onDeleted: () {
                  setState(() {
                    selectedList.remove(item);
                  });
                },
                deleteIcon: const Icon(Icons.cancel, size: 16),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.blue[50],
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

// 직접 입력을 위한 간단한 다이얼로그
  void _showAddCustomDialog(String title, Function(String) onAdd) {
    final TextEditingController customController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('새로운 $title 추가'),
        content: TextField(
          controller: customController,
          decoration: InputDecoration(hintText: '$title 명칭 입력'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              onAdd(customController.text);
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('상품 이미지 (첫 번째 사진이 썸네일이 됩니다)'),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_a_photo, color: Colors.grey),
                  ),
                );
              }
              return Stack(
                children: [
                  Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedImages.removeAt(index)),
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
