class Product {
  final String id;
  final String name;

  final List<String> theme;
  final List<String> seller;
  final List<String> categoryGroup;

  final int basePrice;
  final List<String> images;
  final String description;

  final int stock;
  final bool isAvailable;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get canOrder => isAvailable && stock > 0;

  Product({
    required this.id,
    required this.name,
    required this.theme,
    required this.categoryGroup,
    required this.seller,
    required this.basePrice,
    required this.description,
    required this.images,
    required this.stock,
    required this.createdAt,
    required this.updatedAt,
    this.isAvailable = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      theme: List<String>.from(json['theme'] ?? []),
      categoryGroup: List<String>.from(json['categoryGroup'] ?? []),
      seller: List<String>.from(json['seller'] ?? []),
      basePrice: json['basePrice'],
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      stock: json['stock'] ?? 999,
      isAvailable: json['isAvailable'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'theme': theme,
        'categoryGroup': categoryGroup,
        'seller': seller,
        'basePrice': basePrice,
        'description': description,
        'images': images,
        'stock': stock,
        'isAvailable': isAvailable,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Product copyWith({
    String? id,
    String? name,
    List<String>? theme,
    List<String>? categoryGroup,
    List<String>? seller,
    int? basePrice,
    String? description,
    List<String>? images,
    int? stock,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      theme: theme ?? this.theme,
      categoryGroup: categoryGroup ?? this.categoryGroup,
      seller: seller ?? this.seller,
      basePrice: basePrice ?? this.basePrice,
      description: description ?? this.description,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
