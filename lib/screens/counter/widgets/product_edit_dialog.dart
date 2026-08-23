import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiosk/models/product_image_model.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/dao_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:kiosk/theme/common_theme.dart';

class ProductEditDialog extends ConsumerStatefulWidget {
  final ProductModel product;
  const ProductEditDialog({super.key, required this.product});

  @override
  ConsumerState<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends ConsumerState<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descController;

  final List<dynamic> _images = []; // ProductImageModel 또는 File 객체 유지
  final ImagePicker _picker = ImagePicker();

  List<String> _selectedThemes = [];
  List<String> _selectedSellers = [];
  List<String> _selectedCategories = [];

  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController =
        TextEditingController(text: widget.product.basePrice.toString());
    _stockController =
        TextEditingController(text: widget.product.stock.toString());
    _descController = TextEditingController(text: widget.product.description);
    _isAvailable = widget.product.isAvailable;

    _images.addAll(widget.product.images);
    _selectedThemes = List.from(widget.product.themes);
    _selectedSellers = List.from(widget.product.sellers);
    _selectedCategories = List.from(widget.product.categories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _images.addAll(images.map((e) => File(e.path))));
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final appDir = await getApplicationDocumentsDirectory();
    final productDir = Directory(p.join(appDir.path, 'product_images'));
    if (!await productDir.exists()) await productDir.create();

    List<ProductImageModel> finalImageModels = [];
    for (int i = 0; i < _images.length; i++) {
      final img = _images[i];
      if (img is ProductImageModel) {
        // 기존 이미지: 순서와 썸네일 여부만 갱신하여 유지
        finalImageModels.add(img.copyWith(sortOrder: i, isThumbnail: i == 0));
      } else if (img is File) {
        // 새 이미지: 로컬 복사 후 모델 생성
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${p.basename(img.path)}';
        final localPath = p.join(productDir.path, fileName);
        await img.copy(localPath);
        finalImageModels.add(ProductImageModel(
          id: 0,
          productId: widget.product.id,
          imagePath: localPath,
          isThumbnail: i == 0,
          sortOrder: i,
          createdAt: DateTime.now(),
        ));
      }
    }

    final updatedProduct = widget.product.copyWith(
      name: _nameController.text,
      basePrice: int.parse(_priceController.text),
      stock: int.parse(_stockController.text),
      description: _descController.text,
      isAvailable: _isAvailable,
      images: finalImageModels,
      themes: _selectedThemes,
      sellers: _selectedSellers,
      categories: _selectedCategories,
      updatedAt: DateTime.now(),
    );

    // Notifier를 통해 DB 업데이트 및 실시간 동기화 브로드캐스트 실행
    await ref.read(productProvider.notifier).updateProduct(updatedProduct);

    if (mounted) Navigator.pop(context);
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: PageColors.cateSelect),
      filled: true,
      fillColor: const Color(0xFFF8F9FA), // 아주 연한 회색 배경 추가
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: PageColors.cateSelect, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterDao = ref.watch(filterDaoProvider);

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white, // 다이얼로그 틴트 제거로 흰색 유지
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('[${widget.product.name}] 정보 수정',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text('상품의 상세 정보를 변경할 수 있습니다.',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal)),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImageSection(),
                const SizedBox(height: 24),

                // 상품명 입력 필드
                TextFormField(
                  controller: _nameController,
                  decoration:
                      _inputDecoration('상품명', Icons.shopping_bag_outlined),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  validator: (v) => v!.isEmpty ? '이름을 입력하세요' : null,
                ),
                const SizedBox(height: 16),

                // 가격 및 재고 입력 필드
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration:
                            _inputDecoration('판매 가격', Icons.payments_outlined),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: PageColors.price,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: _inputDecoration(
                            '현재 재고', Icons.inventory_2_outlined),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 판매 상태 스위치 (디자인 개선)
                Container(
                  decoration: BoxDecoration(
                    color: _isAvailable
                        ? Colors.green.withOpacity(0.05)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _isAvailable
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey.shade300),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      _isAvailable ? '키오스크 판매 중' : '키오스크 판매 중지',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isAvailable
                              ? Colors.green[700]
                              : Colors.grey[700]),
                    ),
                    subtitle: const Text('비활성화 시 키오스크 목록에서 숨겨집니다.'),
                    value: _isAvailable,
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green[100],
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[200],
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                ),

                const Divider(),

                // 분류 정보 섹션 (배경 추가)
                _buildTagRow(filterDao),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration:
                      _inputDecoration('상품 상세 설명', Icons.description_outlined),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소')),
        ElevatedButton(
            onPressed: _saveProduct, child: const Text('변경사항 저장 및 동기화')),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('상품 이미지 관리 (첫 번째 사진이 썸네일)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + 1,
            itemBuilder: (context, index) {
              if (index == _images.length) {
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
                              ? FileImage(File(img.imagePath)) // 로컬 경로 이미지
                              : FileImage(img as File), // 새로 선택한 이미지
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

  Widget _buildTagRow(dynamic filterDao) {
    return Column(
      children: [
        _buildManageableSection('테마', filterDao.getThemes(), _selectedThemes,
            Icons.palette_outlined),
        _buildManageableSection('판매자', filterDao.getSellers(), _selectedSellers,
            Icons.storefront_outlined),
        _buildManageableSection('카테고리', filterDao.getCategories(),
            _selectedCategories, Icons.category_outlined),
      ],
    );
  }

  Widget _buildManageableSection(String title, Future<List<String>> future,
      List<String> selectedList, IconData icon // 아이콘 추가
      ) {
    return FutureBuilder<List<String>>(
      future: future,
      builder: (context, snapshot) {
        final options = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(icon, size: 18, color: PageColors.cateSelect), // 제목 옆 아이콘
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                TextButton.icon(
                  // 직접입력 버튼 가시성 강화
                  onPressed: () => _showAddTagDialog(title, selectedList),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('직접입력', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                )
              ],
            ),
            const SizedBox(height: 6),
            // 드롭다운에도 _inputDecoration 스타일 적용
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('$title 선택', icon).copyWith(
                prefixIcon: null, // 타이틀에 이미 아이콘이 있으므로 제거
                hintText: '$title을 선택하세요',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              dropdownColor: Colors.white,
              items: options
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null && !selectedList.contains(v)) {
                  setState(() => selectedList.add(v));
                }
              },
            ),
            if (selectedList.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedList
                    .map((s) => Chip(
                          label: Text(s,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                          onDeleted: () =>
                              setState(() => selectedList.remove(s)),
                          backgroundColor: PageColors.buttonBack,
                          side: BorderSide(
                              color: PageColors.cateSelect.withOpacity(0.1)),
                          deleteIconColor: Colors.red[300],
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ))
                    .toList(),
              ),
            ],
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
}
