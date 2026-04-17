import 'package:flutter/cupertino.dart';

class Product {
  final String id; //  id
  final String name; //  이름

  final List<String> categoryGroup1;
  final List<String> categoryGroup2;
  final List<String> categoryGroup3;

  final int basePrice;
  final List<String> images;
  final List<ProductOption> options;

  final String description;

  final int stock;
  final bool isAvailable;

  bool get canOrder => isAvailable && stock > 0;

  Product({
    required this.id,
    required this.name,
    required this.categoryGroup1,
    required this.categoryGroup2,
    required this.categoryGroup3,
    required this.basePrice,
    required this.description,
    required this.images,
    required this.options,
    required this.stock,
    this.isAvailable = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      categoryGroup1: List<String>.from(json['categoryGroup1'] ?? []),
      categoryGroup2: List<String>.from(json['categoryGroup2'] ?? []),
      categoryGroup3: List<String>.from(json['categoryGroup3'] ?? []),
      basePrice: json['basePrice'],
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      options: (json['options'] as List? ?? [])
          .map((e) => ProductOption.fromJson(e))
          .toList(),
      stock: json['stock'] ?? 999, // 없을시 999 (디버깅 용
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryGroup1': categoryGroup1,
        'categoryGroup2': categoryGroup2,
        'categoryGroup3': categoryGroup3,
        'basePrice': basePrice,
        'description': description,
        'images': images,
        'options': options.map((e) => e.toJson()).toList(),
        'stock': stock,
        'isAvailable': isAvailable,
      };
}

class ProductOption {
  final String name;
  final List<OptionItem> items;

  ProductOption({
    required this.name,
    required this.items,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      name: json['name'],
      items: (json['items'] as List? ?? [])
          .map((e) => OptionItem.fromJson(e))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => {
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class OptionItem {
  final String name;
  final int price;

  OptionItem({
    required this.name,
    required this.price,
  });

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    return OptionItem(
      name: json['name'],
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
      };
}
