// lib/screens/counter/widgets/product_set_add_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiosk/models/product_image_model.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/dao_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/screens/counter/widgets/image_crop_dialog.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/image_util.dart';
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

  dynamic _thumbnailImage; // ProductImageModel 또는 File (크롭 썸네일)
  File? _thumbnailOriginalFile; // 썸네일 크롭 전 원본 파일
  final List<dynamic> _detailImages = []; // ProductImageModel 또는 File 리스트

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

    // ★ 1. 첫 번째 구성품의 대표 이미지를 썸네일 초기값으로 사용
    if (widget.components.isNotEmpty &&
        widget.components.first.images.isNotEmpty) {
      _thumbnailImage = widget.components.first.images.first;
    }

    // ★ 2. 모든 구성품들의 이미지들을 상세 이미지 목록으로 자동 분리 등록
    for (var p in widget.components) {
      for (var img in p.images) {
        _detailImages.add(img);
      }
    }
  }

  /// 1. 새로운 썸네일 지정 (크롭 수행 + 원본을 상세 목록에 추가)
  Future<void> _pickThumbnailImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final File originalFile = File(image.path);
    final croppedFile = await ImageCropDialog.cropFile(context, originalFile);

    if (croppedFile != null) {
      setState(() {
        _thumbnailImage = croppedFile;
        _thumbnailOriginalFile = originalFile;

        if (!_detailImages.contains(originalFile)) {
          _detailImages.insert(0, originalFile);
        }
      });
    }
  }

  /// 썸네일 재크롭
  Future<void> _recropThumbnail() async {
    File? sourceFile;
    if (_thumbnailOriginalFile != null) {
      sourceFile = _thumbnailOriginalFile;
    } else if (_thumbnailImage is ProductImageModel) {
      sourceFile = File((_thumbnailImage as ProductImageModel).imagePath);
    } else if (_thumbnailImage is File) {
      sourceFile = _thumbnailImage as File;
    }

    if (sourceFile != null && await sourceFile.exists()) {
      final croppedFile = await ImageCropDialog.cropFile(context, sourceFile);
      if (croppedFile != null) {
        setState(() {
          _thumbnailImage = croppedFile;
        });
      }
    }
  }

  /// 2. 상세 이미지 여러 장 추가
  Future<void> _pickDetailImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _detailImages.addAll(images.map((e) => File(e.path))));
    }
  }

  Future<void> _saveSetProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final appDir = await getApplicationDocumentsDirectory();
    final productDir = Directory(p.join(appDir.path, 'product_images'));
    if (!await productDir.exists()) await productDir.create();

    List<ProductImageModel> finalImageModels = [];

    // A. 썸네일 이미지 처리 (isThumbnail: true, sortOrder: 0)
    if (_thumbnailImage is ProductImageModel) {
      finalImageModels.add((_thumbnailImage as ProductImageModel)
          .copyWith(sortOrder: 0, isThumbnail: true));
    } else if (_thumbnailImage is File) {
      final fileName = 'thumb_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final localPath = p.join(productDir.path, fileName);
      await ImageUtil.compressAndSave(_thumbnailImage as File, localPath);

      finalImageModels.add(ProductImageModel(
        id: 0,
        productId: 0,
        imagePath: localPath,
        isThumbnail: true,
        sortOrder: 0,
        createdAt: DateTime.now(),
      ));
    }

    // B. 상세 원본 이미지 목록 처리 (isThumbnail: false, sortOrder: 1, 2, ...)
    for (int i = 0; i < _detailImages.length; i++) {
      final img = _detailImages[i];
      if (img is ProductImageModel) {
        finalImageModels
            .add(img.copyWith(sortOrder: i + 1, isThumbnail: false));
      } else if (img is File) {
        final fileName =
            'detail_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
        final localPath = p.join(productDir.path, fileName);
        await ImageUtil.compressAndSave(img, localPath);

        finalImageModels.add(ProductImageModel(
          id: 0,
          productId: 0,
          imagePath: localPath,
          isThumbnail: false,
          sortOrder: i + 1,
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
    final filterDao = ref.watch(filterDaoProvider);

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

  /// 썸네일 & 상세 이미지 분리 UI 섹션
  Widget _buildImageSection() {
    ImageProvider? thumbProvider;
    if (_thumbnailImage is ProductImageModel) {
      thumbProvider =
          FileImage(File((_thumbnailImage as ProductImageModel).imagePath));
    } else if (_thumbnailImage is File) {
      thumbProvider = FileImage(_thumbnailImage as File);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 썸네일 전용 영역
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
            if (thumbProvider != null)
              Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 2),
                      image: DecorationImage(
                          image: thumbProvider, fit: BoxFit.cover),
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
                      onTap: () => setState(() => _thumbnailImage = null),
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

        // 2. 상세 정보 이미지 영역 (모든 구성품 원본 이미지들이 수집됨)
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

              final img = _detailImages[index];
              ImageProvider detailProvider;
              if (img is ProductImageModel) {
                detailProvider = FileImage(File(img.imagePath));
              } else {
                detailProvider = FileImage(img as File);
              }

              return Stack(
                children: [
                  Container(
                    width: 95,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                          image: detailProvider, fit: BoxFit.cover),
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
