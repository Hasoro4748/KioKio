import 'dart:convert';

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
    // 1. 상품 전체 목록 1회 조회
    final products = await productDao.getAll();
    if (products.isEmpty) return [];

    // 2. 전체 이미지 데이터 1회 조회 (N번 쿼리 ➔ 1번 쿼리로 단축)
    final allImages = await imageDao.getAllImages(); // 전체 이미지 읽기
    final imageMap = <int, List<ProductImageModel>>{};
    for (var img in allImages) {
      imageMap
          .putIfAbsent(img.productId, () => [])
          .add(ProductImageMapper.fromData(img));
    }

    final result = <ProductModel>[];

    for (final p in products) {
      final images = imageMap[p.id] ?? [];
      final themes = await relationDao.getThemes(p.id);
      final sellers = await relationDao.getSellers(p.id);
      final categories = await relationDao.getCategories(p.id);

      int currentStock = p.stock;
      if (p.isSet && p.componentIds != null) {
        final List<int> ids = List<int>.from(jsonDecode(p.componentIds!));
        int minStock = 999999;
        for (var id in ids) {
          final comp = await productDao.getById(id);
          if (comp != null && comp.stock < minStock) {
            minStock = comp.stock;
          }
        }
        currentStock = minStock == 999999 ? 0 : minStock;
      }

      result.add(
        ProductModel(
          id: p.id,
          name: p.name,
          themes: themes,
          sellers: sellers,
          categories: categories,
          basePrice: p.basePrice,
          images: images,
          description: p.description,
          stock: currentStock,
          isSet: p.isSet,
          componentIds: p.componentIds != null
              ? List<int>.from(jsonDecode(p.componentIds!))
              : [],
          isAvailable: p.isAvailable,
          displayOrder: p.displayOrder,
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
      displayOrder: product.displayOrder, // ★ 추가
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      isSet: product.isSet,
      componentIds: product.componentIds != null
          ? List<int>.from(jsonDecode(product.componentIds!))
          : [],
    );
  }

  Future<ProductModel> getProductSimple(int id) async {
    final product = await productDao.getById(id);

    return ProductModel(
      id: product!.id,
      name: product.name,
      themes: [],
      sellers: [],
      categories: [],
      basePrice: product.basePrice,
      images: [],
      description: product.description,
      stock: product.stock,
      isAvailable: product.isAvailable,
      displayOrder: product.displayOrder, // ★ 추가
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }

  /// 상품 데이터 초기화
  Future<void> clearAllProducts() async {
    await db.transaction(() async {
      await db.delete(db.productThemes).go();
      await db.delete(db.productSellers).go();
      await db.delete(db.productCategories).go();
      await db.delete(db.productImages).go();
      await db.delete(db.products).go();

      await db.delete(db.themes).go();
      await db.delete(db.sellers).go();
      await db.delete(db.categories).go();
    });
  }

  /// 여러 상품 재고 일괄 차감 (결제 시 속도 최적화)
  Future<void> updateStocksBatch(Map<int, int> stockUpdates) async {
    await db.transaction(() async {
      for (var entry in stockUpdates.entries) {
        await productDao.updateProductStock(entry.key, entry.value);
      }
    });
  }

  Future<void> addProduct(ProductModel model) async {
    await db.transaction(() async {
      final allProducts = await productDao.getAll();
      final maxOrder = allProducts.isEmpty
          ? 0
          : allProducts
              .map((p) => p.displayOrder)
              .reduce((a, b) => a > b ? a : b);

      // 신규 상품은 맨 마지막(maxOrder + 1) 순서 부여
      final productWithOrder = model.copyWith(displayOrder: maxOrder + 1);

      // insert 대신 insert(..., mode: InsertMode.replace) 사용
      final productId = await db.into(db.products).insert(
            ProductMapper.toCompanion(productWithOrder),
            mode: InsertMode.replace,
          );

      // 기존 이미지 삭제 후 다시 추가 (중복 방지)
      await imageDao.deleteByProductId(productId);
      for (var imageModel in model.images) {
        await imageDao.insert(ProductImageMapper.toSaveCompanion(imageModel)
            .copyWith(id: const Value.absent(), productId: Value(productId)));
      }

      // 관계 업데이트 (이미 clearRelations가 포함되어 있다면 유지)
      await relationDao.clearRelations(productId);
      await _updateRelations(productId, model);
    });
  }

  Future<void> updateProduct(ProductModel model) async {
    await db.transaction(() async {
      final productId = model.id;
      // 상품 기본 정보 업데이트
      await productDao.updateProduct(ProductMapper.toCompanion(model));
      // 기존 이미지 삭제 후 다시 추가
      await imageDao.deleteByProductId(productId);
      for (var imageModel in model.images) {
        await imageDao.insert(ProductImageMapper.toSaveCompanion(imageModel)
            .copyWith(id: const Value.absent(), productId: Value(productId)));
      }
      // 관계 초기화 후 재생성
      await relationDao.clearRelations(model.id);
      await _updateRelations(productId, model);
    });
  }

  /// 상품 표시 순서 일괄 업데이트
  Future<void> updateProductOrders(List<ProductModel> reorderedProducts) async {
    await db.transaction(() async {
      for (int i = 0; i < reorderedProducts.length; i++) {
        final product = reorderedProducts[i];
        // 순서 번호(0, 1, 2, ...)로 일괄 업데이트
        await (db.update(db.products)..where((p) => p.id.equals(product.id)))
            .write(ProductsCompanion(displayOrder: Value(i)));
      }
    });
  }

  Future<void> updateStock(int id, int stock) async {
    print("상품 개수 조절 : $id번 $stock개로 수정");
    await productDao.updateProductStock(id, stock);
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
