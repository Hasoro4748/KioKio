import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/models/product_image_model.dart';

class ProductImageMapper {
  static ProductImageModel fromData(ProductImage data) {
    return ProductImageModel(
      id: data.id,
      productId: data.productId,
      imagePath: data.imagePath,
      sortOrder: data.sortOrder,
      isThumbnail: data.isThumbnail,
      createdAt: data.createdAt,
    );
  }

  static ProductImagesCompanion toCompanion(
    ProductImageModel model,
  ) {
    return ProductImagesCompanion(
      id: Value(model.id),
      productId: Value(model.productId),
      imagePath: Value(model.imagePath),
      sortOrder: Value(model.sortOrder),
      isThumbnail: Value(model.isThumbnail),
      createdAt: Value(model.createdAt),
    );
  }
}
