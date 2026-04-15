import 'package:flutter/cupertino.dart';

class Product {
  final String id; //  id
  final String name; //  이름

  final String category1; // 대분류
  final String category2; //  중분류
  final String category3; //  종류

  final int basePrice; //  가격

  final List<String> images; //  이미지 경로

  final List<ProductOption> options;

  final bool isAvailable; //  매진 여부

  Product({
    required this.id,
    required this.name,
    required this.category1,
    required this.category2,
    required this.category3,
    required this.basePrice,
    required this.images,
    required this.options,
    this.isAvailable = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      category1: json['category1'],
      category2: json['category2'],
      category3: json['category3'],
      basePrice: json['basePrice'],
      images: List<String>.from(json['images'] ?? []),
      options: (json['options'] as List? ?? [])
          .map((e) => ProductOption.fromJson(e))
          .toList(),
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category1': category1,
        'category2': category2,
        'category3': category3,
        'basePrice': basePrice,
        'images': images,
        'options': options.map((e) => e.toJson()).toList(),
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
