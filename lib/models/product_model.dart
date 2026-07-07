import 'package:kiosk/models/product_image_model.dart';

class ProductModel {
  final int id;

  final String name;

  final List<String> themes;

  final List<String> sellers;

  final List<String> categories;

  final int basePrice;

  final List<ProductImageModel> images;

  final String description;

  final int stock;

  final bool isAvailable;

  final DateTime createdAt;

  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.themes,
    required this.sellers,
    required this.categories,
    required this.basePrice,
    required this.images,
    required this.description,
    required this.stock,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canOrder => isAvailable && stock > 0;

  ProductModel copyWith({
    int? id,
    String? name,
    List<String>? themes,
    List<String>? sellers,
    List<String>? categories,
    int? basePrice,
    List<ProductImageModel>? images,
    String? description,
    int? stock,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      themes: themes ?? this.themes,
      sellers: sellers ?? this.sellers,
      categories: categories ?? this.categories,
      basePrice: basePrice ?? this.basePrice,
      images: images ?? this.images,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get thumbnail {
    final thumb = images.where((e) => e.isThumbnail).firstOrNull;

    if (thumb != null) {
      return thumb.imagePath;
    }

    if (images.isNotEmpty) {
      return images.first.imagePath;
    }

    return "assets/img/unit/no_image.png";
    ;
  }
}
