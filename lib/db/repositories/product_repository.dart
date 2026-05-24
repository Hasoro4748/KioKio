import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/db/mapper/product_mapper.dart';
import 'package:kiosk/models/product_model.dart';

class ProductRepository {
  final AppDatabase db;

  ProductRepository(this.db);

  /// 전체 상품 조회
  Future<List<ProductModel>> getProducts() async {
    final productList = await db.select(db.products).get();

    List<ProductModel> result = [];

    for (final product in productList) {
      final imageList = await (db.select(db.productImages)
            ..where((tbl) => tbl.productId.equals(product.id))
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
            ]))
          .get();

      result.add(
        ProductMapper.toModel(
          product: product,
          images: imageList,
        ),
      );
    }

    return result;
  }

  /// 상품 추가
  Future<void> addProduct(ProductModel product) async {
    await db.transaction(() async {
      /// 1. 상품 저장
      final productId = await db.into(db.products).insert(
            ProductMapper.toCompanion(product),
          );

      /// 2. 이미지 저장
      for (int i = 0; i < product.images.length; i++) {
        await db.into(db.productImages).insert(
              ProductImagesCompanion.insert(
                productId: productId,
                imagePath: product.images[i],
                sortOrder: Value(i),
                isThumbnail: Value(i == 0),
                createdAt: DateTime.now(),
              ),
            );
      }
    });
  }

  /// 상품 수정
  Future<bool> updateProduct(ProductModel product) async {
    return await db.transaction(() async {
      /// 1. 상품 수정
      final updated = await db.update(db.products).replace(
            Product(
              id: product.id,
              name: product.name,
              theme: product.theme,
              seller: product.seller,
              categoryGroup: product.categoryGroup,
              basePrice: product.basePrice,
              description: product.description,
              stock: product.stock,
              isAvailable: product.isAvailable,
              createdAt: product.createdAt,
              updatedAt: DateTime.now(),
            ),
          );

      /// 2. 기존 이미지 삭제
      await (db.delete(db.productImages)
            ..where((tbl) => tbl.productId.equals(product.id)))
          .go();

      /// 3. 새 이미지 저장
      for (int i = 0; i < product.images.length; i++) {
        await db.into(db.productImages).insert(
              ProductImagesCompanion.insert(
                productId: product.id,
                imagePath: product.images[i],
                sortOrder: Value(i),
                isThumbnail: Value(i == 0),
                createdAt: DateTime.now(),
              ),
            );
      }

      return updated;
    });
  }

  /// 상품 삭제
  Future<int> deleteProduct(int id) {
    return (db.delete(db.products)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 재고 수정
  Future<void> updateStock({
    required int id,
    required int stock,
  }) async {
    await (db.update(db.products)..where((tbl) => tbl.id.equals(id))).write(
      ProductsCompanion(
        stock: Value(stock),
      ),
    );
  }
}
