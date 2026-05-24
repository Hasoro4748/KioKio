import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/models/product_model.dart';

class ProductMapper {
  static ProductModel toModel({
    required Product product,
    required List<ProductImage> images,
  }) {
    return ProductModel(
      id: product.id,
      name: product.name,
      theme: product.theme,
      seller: product.seller,
      categoryGroup: product.categoryGroup,
      basePrice: product.basePrice,
      images: images.map((e) => e.imagePath).toList(),
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
      theme: model.theme,
      seller: model.seller,
      categoryGroup: model.categoryGroup,
      basePrice: model.basePrice,
      description: model.description,
      stock: Value(model.stock),
      isAvailable: Value(model.isAvailable),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
