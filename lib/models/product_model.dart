class ProductModel {
  final int id;

  final String name;

  final String theme;

  final String seller;

  final String categoryGroup;

  final int basePrice;

  final List<String> images;

  final String description;

  final int stock;

  final bool isAvailable;

  final DateTime createdAt;

  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.theme,
    required this.seller,
    required this.categoryGroup,
    required this.basePrice,
    required this.images,
    required this.description,
    required this.stock,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canOrder => isAvailable && stock > 0;
  String get thumbnail =>
      images.isNotEmpty ? images.first : "assets/img/unit/no_image.png";
}
