import 'dart:io';
import 'package:collection/collection.dart';
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
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/image_util.dart';

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

  dynamic _thumbnailImage; // ProductImageModel 또는 File (크롭 썸네일)
  File? _thumbnailOriginalFile; // 썸네일 크롭 전 원본 파일
  final List<dynamic> _detailImages = []; // ProductImageModel 또는 File 리스트

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

    // 이미지 분리 로드
    final thumb =
        widget.product.images.firstWhereOrNull((img) => img.isThumbnail);
    _thumbnailImage = thumb ?? widget.product.images.firstOrNull;

    final details =
        widget.product.images.where((img) => !img.isThumbnail).toList();
    _detailImages.addAll(details);

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

  /// 1. 새로운 썸네일 지정 (크롭 수행 + 원본을 상세 이미지 목록에 자동 삽입)
  Future<void> _pickThumbnailImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final File originalFile = File(image.path);
    final croppedFile = await ImageCropDialog.cropFile(context, originalFile);

    if (croppedFile != null) {
      setState(() {
        _thumbnailImage = croppedFile;
        _thumbnailOriginalFile = originalFile;

        // 원본 이미지가 상세 이미지 목록에 없다면 맨 앞에 추가
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

  /// 2. 상세 정보용 이미지 여러 장 추가
  Future<void> _pickDetailImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _detailImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final appDir = await getApplicationDocumentsDirectory();
    final productDir = Directory(p.join(appDir.path, 'product_images'));
    if (!await productDir.exists()) await productDir.create();

    List<ProductImageModel> finalImageModels = [];

    // 1. 썸네일 처리
    if (_thumbnailImage is ProductImageModel) {
      finalImageModels.add((_thumbnailImage as ProductImageModel)
          .copyWith(sortOrder: 0, isThumbnail: true));
    } else if (_thumbnailImage is File) {
      final fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = p.join(productDir.path, fileName);
      await ImageUtil.compressAndSave(_thumbnailImage as File, localPath);

      finalImageModels.add(ProductImageModel(
        id: 0,
        productId: widget.product.id,
        imagePath: localPath,
        isThumbnail: true,
        sortOrder: 0,
        createdAt: DateTime.now(),
      ));
    }

    // 2. 상세 이미지들 처리
    for (int i = 0; i < _detailImages.length; i++) {
      final img = _detailImages[i];
      if (img is ProductImageModel) {
        finalImageModels
            .add(img.copyWith(sortOrder: i + 1, isThumbnail: false));
      } else if (img is File) {
        final fileName =
            'detail_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final localPath = p.join(productDir.path, fileName);
        await ImageUtil.compressAndSave(img, localPath);

        finalImageModels.add(ProductImageModel(
          id: 0,
          productId: widget.product.id,
          imagePath: localPath,
          isThumbnail: false,
          sortOrder: i + 1,
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

    await ref.read(productProvider.notifier).updateProduct(updatedProduct);
    if (mounted) Navigator.pop(context);
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: PageColors.cateSelect),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
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
      surfaceTintColor: Colors.white,
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
                TextFormField(
                  controller: _nameController,
                  decoration:
                      _inputDecoration('상품명', Icons.shopping_bag_outlined),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  validator: (v) => v!.isEmpty ? '이름을 입력하세요' : null,
                ),
                const SizedBox(height: 16),
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
        // 1. 썸네일 영역
        Row(
          children: const [
            Icon(Icons.crop_square_rounded, color: Colors.orange, size: 18),
            SizedBox(width: 6),
            Text('상품 썸네일 이미지',
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

        // 2. 상세 정보 이미지 영역
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
      List<String> selectedList, IconData icon) {
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
                Icon(icon, size: 18, color: PageColors.cateSelect),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddTagDialog(title, selectedList),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('직접입력', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                )
              ],
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('$title 선택', icon).copyWith(
                prefixIcon: null,
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
