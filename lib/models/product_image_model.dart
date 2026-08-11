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

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'imagePath': imagePath,
        'sortOrder': sortOrder,
        'isThumbnail': isThumbnail,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProductImageModel.fromJson(Map<String, dynamic> json) =>
      ProductImageModel(
          id: json['id'],
          productId: json['productId'],
          imagePath: json['imagePath'],
          sortOrder: json['sortOrder'],
          isThumbnail: json['isThumbnail'],
          createdAt: DateTime.parse(json['createdAt']));
}
