import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';

class RelationDao {
  final AppDatabase db;

  RelationDao(this.db);

  /// 테마 조회
  Future<List<String>> getThemes(int productId) async {
    final query = db.select(db.productThemes).join([
      innerJoin(
        db.themes,
        db.themes.id.equalsExp(db.productThemes.themeId),
      ),
    ])
      ..where(db.productThemes.productId.equals(productId));

    final rows = await query.get();
    return rows.map((e) => e.readTable(db.themes).name).toList();
  }

  /// 판매자 조회
  Future<List<String>> getSellers(int productId) async {
    final query = db.select(db.productSellers).join([
      innerJoin(
        db.sellers,
        db.sellers.id.equalsExp(db.productSellers.sellerId),
      ),
    ])
      ..where(db.productSellers.productId.equals(productId));

    final rows = await query.get();

    return rows.map((e) => e.readTable(db.sellers).name).toList();
  }

  /// 카테고리 조회
  Future<List<String>> getCategories(int productId) async {
    final query = db.select(db.productCategories).join([
      innerJoin(
        db.categories,
        db.categories.id.equalsExp(db.productCategories.categoryId),
      ),
    ])
      ..where(db.productCategories.productId.equals(productId));

    final rows = await query.get();

    return rows.map((e) => e.readTable(db.categories).name).toList();
  }

  /// 상품-테마 관계 추가
  Future<void> insertProductTheme(int productId, int themeId) async {
    await db.into(db.productThemes).insert(
          ProductThemesCompanion.insert(
            productId: productId,
            themeId: themeId,
          ),
          mode: InsertMode.insertOrIgnore, // 중복 삽입 방지
        );
  }

  /// 상품-판매자 관계 추가
  Future<void> insertProductSeller(int productId, int sellerId) async {
    await db.into(db.productSellers).insert(
          ProductSellersCompanion.insert(
            productId: productId,
            sellerId: sellerId,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// 상품-카테고리 관계 추가
  Future<void> insertProductCategory(int productId, int categoryId) async {
    await db.into(db.productCategories).insert(
          ProductCategoriesCompanion.insert(
            productId: productId,
            categoryId: categoryId,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> clearRelations(int productId) async {
    await (db.delete(db.productThemes)
          ..where((t) => t.productId.equals(productId)))
        .go();
    await (db.delete(db.productSellers)
          ..where((t) => t.productId.equals(productId)))
        .go();
    await (db.delete(db.productCategories)
          ..where((t) => t.productId.equals(productId)))
        .go();
  }
}
