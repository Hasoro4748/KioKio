import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';

class ImageDao {
  final AppDatabase db;

  ImageDao(this.db);

  Future<List<ProductImage>> getByProductId(int productId) {
    return (db.select(db.productImages)
          ..where((i) => i.productId.equals(productId))
          ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
        .get();
  }

  Future insertImages(int productId, List<String> paths) async {
    for (int i = 0; i < paths.length; i++) {
      await db.into(db.productImages).insert(ProductImagesCompanion.insert(
          productId: productId,
          imagePath: paths[i],
          sortOrder: Value(i),
          isThumbnail: Value(i == 0),
          createdAt: DateTime.now()));
    }
  }
}
