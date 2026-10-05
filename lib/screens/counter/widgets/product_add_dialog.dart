import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiosk/models/product_image_model.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/dao_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/screens/counter/widgets/image_crop_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:kiosk/utils/image_util.dart';

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

  File? _thumbnailFile; // 1:1 크롭된 썸네일 파일
  File? _thumbnailOriginalFile; // 썸네일의 크롭 전 원본 파일
  final List<File> _detailImages = []; // 상세 페이지용 원본 이미지 리스트
  final ImagePicker _picker = ImagePicker();

  List<String> _selectedThemes = [];
  List<String> _selectedSellers = [];
  List<String> _selectedCategories = [];

  final List<String> _localNewThemes = [];
  final List<String> _localNewSellers = [];
  final List<String> _localNewCategories = [];

  bool _isSaving = false;

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

  /// 1. 썸네일 이미지 전용 선택 (크롭 수행 + 원본을 상세 목록에 자동 추가)
  Future<void> _pickThumbnailImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final File originalFile = File(image.path);
    final croppedFile = await ImageCropDialog.cropFile(context, originalFile);

    if (croppedFile != null) {
      setState(() {
        _thumbnailFile = croppedFile;
        _thumbnailOriginalFile = originalFile;

        // 크롭 전 원본 이미지가 상세 이미지 목록에 없다면 맨 앞에 자동 삽입!
        if (!_detailImages.contains(originalFile)) {
          _detailImages.insert(0, originalFile);
        }
      });
    }
  }

  /// 썸네일 영역 재조정 (원본 이미지 기반으로 다시 크롭)
  Future<void> _recropThumbnail() async {
    if (_thumbnailOriginalFile == null) return;
    final croppedFile =
        await ImageCropDialog.cropFile(context, _thumbnailOriginalFile!);
    if (croppedFile != null) {
      setState(() {
        _thumbnailFile = croppedFile;
      });
    }
  }

  /// 2. 상세 정보용 원본 이미지 여러 장 선택
  Future<void> _pickDetailImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() {
      _detailImages.addAll(images.map((e) => File(e.path)));
    });
  }

  /// 상품 저장 로직
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_thumbnailFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품 썸네일 이미지를 등록해 주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final productDir = Directory(p.join(appDir.path, 'product_images'));
      if (!await productDir.exists()) await productDir.create();

      List<ProductImageModel> imageModels = [];

      // A. 크롭된 썸네일 이미지 저장 (isThumbnail: true, sortOrder: 0)
      final thumbName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final thumbPath = p.join(productDir.path, thumbName);
      await ImageUtil.compressAndSave(_thumbnailFile!, thumbPath);

      imageModels.add(ProductImageModel(
        id: 0,
        productId: 0,
        imagePath: thumbPath,
        isThumbnail: true,
        sortOrder: 0,
        createdAt: DateTime.now(),
      ));

      // B. 상세 원본 이미지들 저장 (isThumbnail: false, sortOrder: 1, 2, ...)
      for (int i = 0; i < _detailImages.length; i++) {
        final file = _detailImages[i];
        final fileName =
            'detail_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final localPath = p.join(productDir.path, fileName);
        await ImageUtil.compressAndSave(file, localPath);

        imageModels.add(ProductImageModel(
          id: 0,
          productId: 0,
          imagePath: localPath,
          isThumbnail: false,
          sortOrder: i + 1,
          createdAt: DateTime.now(),
        ));
      }

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

      await ref.read(productProvider.notifier).addProduct(newProduct);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("저장 중 에러: $e");
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('상품 저장 중 오류가 발생했습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterDao = ref.watch(filterDaoProvider);

    return AlertDialog(
      title: const Text('새 상품 등록'),
      content: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: AbsorbPointer(
                  absorbing: _isSaving,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 분리된 이미지 선택 섹션
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
                                  labelText: '가격',
                                  border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? '가격을 입력하세요' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: const InputDecoration(
                                  labelText: '초기 재고',
                                  border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? '재고를 입력하세요' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<String>>(
                        future: filterDao.getThemes(),
                        builder: (context, snapshot) {
                          return _buildManageableChoiceSection(
                            title: '테마',
                            availableItems: snapshot.data ?? [],
                            localNewItems: _localNewThemes,
                            selectedList: _selectedThemes,
                            onAdd: (val) => _onItemAdd(
                                val, _localNewThemes, _selectedThemes),
                          );
                        },
                      ),
                      FutureBuilder<List<String>>(
                        future: filterDao.getSellers(),
                        builder: (context, snapshot) {
                          return _buildManageableChoiceSection(
                            title: '판매자',
                            availableItems: snapshot.data ?? [],
                            localNewItems: _localNewSellers,
                            selectedList: _selectedSellers,
                            onAdd: (val) => _onItemAdd(
                                val, _localNewSellers, _selectedSellers),
                          );
                        },
                      ),
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
          ),
          if (_isSaving)
            Container(
              color: Colors.white70,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('이미지 최적화 및 저장 중...',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('취소')),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProduct,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('저장 및 동기화'),
        ),
      ],
    );
  }

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
    required List<String> availableItems,
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
                items: options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onAdd(newValue);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: () {
                _showAddCustomDialog(title, onAdd);
              },
              icon: const Icon(Icons.edit_note),
              tooltip: '직접 입력',
            ),
          ],
        ),
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

  /// 분리된 이미지 선택 UI
  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. 썸네일 전용 섹션 ---
        Row(
          children: const [
            Icon(Icons.crop_square_rounded, color: Colors.orange, size: 18),
            SizedBox(width: 6),
            Text('썸네일 이미지',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_thumbnailFile != null)
              Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 2),
                      image: DecorationImage(
                        image: FileImage(_thumbnailFile!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: GestureDetector(
                      onTap: _recropThumbnail,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.crop, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('재조정',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _thumbnailFile = null),
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: _pickThumbnailImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.orange.shade300, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo_outlined,
                          color: Colors.orange, size: 28),
                      SizedBox(height: 6),
                      Text('썸네일 등록',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // --- 2. 상세 페이지용 원본 이미지 섹션 ---
        Row(
          children: const [
            Icon(Icons.collections_outlined, color: Colors.blue, size: 18),
            SizedBox(width: 6),
            Text('상세 페이지 이미지',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _detailImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _detailImages.length) {
                return InkWell(
                  onTap: _pickDetailImages,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 95,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: Colors.grey, size: 24),
                        SizedBox(height: 4),
                        Text('사진 추가',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  Container(
                    width: 95,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_detailImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _detailImages.removeAt(index)),
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
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
