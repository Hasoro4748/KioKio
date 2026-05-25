class ProductImageModel {
  final int id;

  final int productId;

  final String imagePath;

  final int sortOrder;

  final bool isThumbnail;

  final DateTime createdAt;

  ProductImageModel({
    required this.id,
    required this.productId,
    required this.imagePath,
    required this.sortOrder,
    required this.isThumbnail,
    required this.createdAt,
  });
}
