import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/models/product_image_model.dart';
import 'package:kiosk/models/product_model.dart';

class ProductMapper {
  static ProductModel toModel({
    required Product product,
    required List<ProductImageModel> images,
    required List<String> themes,
    required List<String> sellers,
    required List<String> categories,
    required List<int> components,
  }) {
    return ProductModel(
      id: product.id,
      name: product.name,
      themes: themes,
      sellers: sellers,
      categories: categories,
      basePrice: product.basePrice,
      images: images,
      description: product.description,
      stock: product.stock,
      isAvailable: product.isAvailable,
      displayOrder: product.displayOrder, // ★ 추가
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      isSet: product.isSet,
      componentIds: components,
    );
  }

  static ProductsCompanion toCompanion(ProductModel model) {
    return ProductsCompanion.insert(
      id: (model.id == 0) ? const Value.absent() : Value(model.id),
      name: model.name,
      basePrice: model.basePrice,
      description: model.description,
      stock: Value(model.stock),
      isAvailable: Value(model.isAvailable),
      displayOrder:
          Value(model.displayOrder), // ★ 추가! (이 부분이 누락되어 0으로 저장되던 현상 수정)
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isSet: Value(model.isSet),
      componentIds: Value(jsonEncode(model.componentIds)),
    );
  }
}
