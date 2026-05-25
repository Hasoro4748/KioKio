import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/db/dao/filter_dao.dart';
import 'package:kiosk/db/dao/image_dao.dart';
import 'package:kiosk/db/dao/product_dao.dart';
import 'package:kiosk/db/dao/relation_dao.dart';
import 'package:kiosk/db/mapper/product_image_mapper.dart';
import 'package:kiosk/db/mapper/product_mapper.dart';
import 'package:kiosk/models/product_image_model.dart';
import 'package:kiosk/models/product_model.dart';

class ProductRepository {
  final ProductDao productDao;
  final ImageDao imageDao;
  final FilterDao filterDao;
  final RelationDao relationDao;
  ProductRepository(
      {required this.productDao,
      required this.imageDao,
      required this.filterDao,
      required this.relationDao});

  /// 전체 상품 조회
  Future<List<ProductModel>> getProducts() async {
    final products = await productDao.getAll();

    final result = <ProductModel>[];

    for (final p in products) {
      final images = await imageDao.getByProductId(p.id);

      final themes = await relationDao.getThemes(p.id);

      final sellers = await relationDao.getSellers(p.id);

      final categories = await relationDao.getCategories(p.id);

      result.add(
        ProductModel(
          id: p.id,
          name: p.name,
          themes: themes,
          sellers: sellers,
          categories: categories,
          basePrice: p.basePrice,
          images: images.map((e) => ProductImageMapper.fromData(e)).toList(),
          description: p.description,
          stock: p.stock,
          isAvailable: p.isAvailable,
          createdAt: p.createdAt,
          updatedAt: p.updatedAt,
        ),
      );
    }

    return result;
  }

  Future<ProductModel> getProductDetail(int id) async {
    final product = await productDao.getById(id);
    final images = await imageDao.getByProductId(id);

    final themes = await relationDao.getThemes(id);

    final sellers = await relationDao.getSellers(id);

    final categories = await relationDao.getCategories(id);

    return ProductModel(
      id: product!.id,
      name: product.name,
      themes: themes,
      sellers: sellers,
      categories: categories,
      basePrice: product.basePrice,
      images: images.map((e) => ProductImageMapper.fromData(e)).toList(),
      description: product.description,
      stock: product.stock,
      isAvailable: product.isAvailable,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }

  //
  // /// 상품 추가
  // Future<void> addProduct(ProductModel product) async {
  //   await db.transaction(() async {
  //     /// 1. 상품 저장
  //     final productId = await db.into(db.products).insert(
  //           ProductMapper.toCompanion(product),
  //         );
  //
  //     /// 2. 이미지 저장
  //     for (int i = 0; i < product.images.length; i++) {
  //       final image = product.images[i];
  //       await db.into(db.productImages).insert(
  //             ProductImagesCompanion.insert(
  //               productId: productId,
  //               imagePath: image.imagePath,
  //               sortOrder: Value(i),
  //               isThumbnail: Value(i == 0),
  //               createdAt: DateTime.now(),
  //             ),
  //           );
  //     }
  //   });
  // }
  //
  // /// 상품 수정
  // Future<bool> updateProduct(ProductModel product) async {
  //   return await db.transaction(() async {
  //     /// 1. 상품 수정
  //     final updated = await db.update(db.products).replace(
  //           Product(
  //             id: product.id,
  //             name: product.name,
  //             theme: product.theme,
  //             seller: product.seller,
  //             categoryGroup: product.categoryGroup,
  //             basePrice: product.basePrice,
  //             description: product.description,
  //             stock: product.stock,
  //             isAvailable: product.isAvailable,
  //             createdAt: product.createdAt,
  //             updatedAt: DateTime.now(),
  //           ),
  //         );
  //
  //     /// 2. 기존 이미지 삭제
  //     await (db.delete(db.productImages)
  //           ..where((tbl) => tbl.productId.equals(product.id)))
  //         .go();
  //
  //     /// 3. 새 이미지 저장
  //     for (int i = 0; i < product.images.length; i++) {
  //       final images = product.images[i];
  //       await db.into(db.productImages).insert(
  //             ProductImagesCompanion.insert(
  //               productId: product.id,
  //               imagePath: images.imagePath,
  //               sortOrder: Value(i),
  //               isThumbnail: Value(i == 0),
  //               createdAt: DateTime.now(),
  //             ),
  //           );
  //     }
  //
  //     return updated;
  //   });
  // }
  //
  // /// 상품 삭제
  // Future<int> deleteProduct(int id) {
  //   return (db.delete(db.products)..where((tbl) => tbl.id.equals(id))).go();
  // }
  //
  // /// 재고 수정
  // Future<void> updateStock({
  //   required int id,
  //   required int stock,
  // }) async {
  //   await (db.update(db.products)..where((tbl) => tbl.id.equals(id))).write(
  //     ProductsCompanion(
  //       stock: Value(stock),
  //     ),
  //   );
  // }
}
