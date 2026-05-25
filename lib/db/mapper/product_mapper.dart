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
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }

  static ProductsCompanion toCompanion(ProductModel model) {
    return ProductsCompanion.insert(
      name: model.name,
      basePrice: model.basePrice,
      description: model.description,
      stock: Value(model.stock),
      isAvailable: Value(model.isAvailable),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
