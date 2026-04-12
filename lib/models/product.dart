import 'package:flutter/cupertino.dart';

class Product {
  final String id; //  id
  final String name; //  이름
  final String pTheme; //  장르
  final String pType; //  종류
  final int price; //  가격
  final String imagePath; //  이미지 경로
  final bool isAvailable; //  매진 여부

  Product({
    required this.id,
    required this.name,
    required this.pTheme,
    required this.pType,
    required this.price,
    required this.imagePath,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pTheme': pTheme,
        'pType': pType,
        'price': price,
        'imagePath': imagePath,
        'isAvailable': isAvailable,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        pTheme: json['pTheme'],
        pType: json['pType'],
        price: json['price'],
        imagePath: json['imagePath'],
        isAvailable: json['isAvailable'] ?? true,
      );
}

class OrderItem {
  final Product product;
  final int quantity;

  OrderItem({required this.product, required this.quantity});

  int get totalPrice => product.price * quantity;
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  int get totalPrice => product.price * quantity;
}
