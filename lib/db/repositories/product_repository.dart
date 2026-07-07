import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/db/dao/filter_dao.dart';
import 'package:kiosk/db/dao/image_dao.dart';
import 'package:kiosk/db/dao/product_dao.dart';
import 'package:kiosk/db/dao/relation_dao.dart';
import 'package:kiosk/db/mapper/product_image_mapper.dart';
import 'package:kiosk/db/mapper/product_mapper.dart';
import 'package:kiosk/models/product_model.dart';

class ProductRepository {
  final AppDatabase db;
  final ProductDao productDao;
  final ImageDao imageDao;
  final FilterDao filterDao;
  final RelationDao relationDao;
  ProductRepository(
      {required this.db,
      required this.productDao,
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

  Future<void> addProduct(ProductModel model) async {
    await db.transaction(() async {
      final productId =
          await productDao.insert(ProductMapper.toCompanion(model));

      for (var imageModel in model.images) {
        await imageDao.insert(ProductImageMapper.toSaveCompanion(imageModel)
            .copyWith(productId: Value(productId)));
      }
      await _updateRelations(productId, model);
    });
  }

  Future<void> updateProduct(ProductModel model) async {
    await db.transaction(() async {
      final productId = model.id;

      await productDao.updateProduct(ProductMapper.toCompanion(model));

      for (var imageModel in model.images) {
        await imageDao.update(ProductImageMapper.toCompanion(imageModel));
      }
      await relationDao.clearRelations(model.id!);
      await _updateRelations(productId, model);
    });
  }

  Future<void> deleteProduct(int productId) async {
    // TODO 상품 삭제

    await db.transaction(() async {
      /// 이미지 삭제
      await imageDao.deleteByProductId(productId);

      /// 관계 제거
      await relationDao.clearRelations(productId);

      /// 상품 제거
      await productDao.delete(productId);
    });
  }

  Future<void> _updateRelations(int productId, ProductModel model) async {
    // 테마 저장
    for (var themeName in model.themes) {
      final themeId = await filterDao.getOrCreateThemeIdByName(themeName);
      await relationDao.insertProductTheme(productId, themeId);
    }
    // 판매자 저장
    for (var sellerName in model.sellers) {
      final sellerId = await filterDao.getOrCreateSellerIdByName(sellerName);
      await relationDao.insertProductSeller(productId, sellerId);
    }
    // 카테고리 저장
    for (var categoryName in model.categories) {
      final categoryId =
          await filterDao.getOrCreateCategoryIdByName(categoryName);
      await relationDao.insertProductCategory(productId, categoryId);
    }
  }
}
