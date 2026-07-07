import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';

class FilterDao {
  final AppDatabase db;

  FilterDao(this.db);

  Future<List<Product>> getByTheme(int themeId) {
    return (db.select(db.products).join([
      innerJoin(
        db.productThemes,
        db.productThemes.productId.equalsExp(db.products.id),
      ),
    ])
          ..where(db.productThemes.themeId.equals(themeId)))
        .map((row) => row.readTable(db.products))
        .get();
  }

  Future<List<String>> getThemes() async {
    final rows = await db.select(db.themes).get();
    return rows.map((e) => e.name).toList();
  }

  /// 모든 판매자 이름 가져오기
  Future<List<String>> getSellers() async {
    final rows = await db.select(db.sellers).get();
    return rows.map((e) => e.name).toList();
  }

  /// 모든 카테고리 이름 가져오기
  Future<List<String>> getCategories() async {
    final rows = await db.select(db.categories).get();
    return rows.map((e) => e.name).toList();
  }

  /// 테마 이름으로 ID 조회
  Future<int?> getThemeIdByName(String themeName) async {
    final query = db.select(db.themes)..where((t) => t.name.equals(themeName));
    final result = await query.getSingleOrNull();
    return result?.id;
  }

  /// 판매자 이름으로 ID 조회
  Future<int?> getSellerIdByName(String sellerName) async {
    final query = db.select(db.sellers)
      ..where((s) => s.name.equals(sellerName));
    final result = await query.getSingleOrNull();
    return result?.id;
  }

  /// 카테고리 이름으로 ID 조회
  Future<int?> getCategoryIdByName(String categoryName) async {
    final query = db.select(db.categories)
      ..where((c) => c.name.equals(categoryName));
    final result = await query.getSingleOrNull();
    return result?.id;
  }

  /// 없을시 생성
  Future<int> getOrCreateThemeIdByName(String themeName) async {
    final existingId = await getThemeIdByName(themeName);
    if (existingId != null) return existingId;

    return await db.into(db.themes).insert(ThemesCompanion.insert(
          name: themeName,
          imagePath: "",
        ));
  }

  Future<int> getOrCreateSellerIdByName(String sellerName) async {
    final existingId = await getSellerIdByName(sellerName);
    if (existingId != null) return existingId;

    return await db.into(db.sellers).insert(SellersCompanion.insert(
          name: sellerName,
        ));
  }

  Future<int> getOrCreateCategoryIdByName(String categoryName) async {
    final existingId = await getCategoryIdByName(categoryName);
    if (existingId != null) return existingId;

    return await db.into(db.categories).insert(CategoriesCompanion.insert(
          name: categoryName,
        ));
  }
}
