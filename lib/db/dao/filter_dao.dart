// lib/db/dao/filter_dao.dart

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
    final rows = await (db.select(db.themes)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.displayOrder, mode: OrderingMode.asc)
          ]))
        .get();
    return rows.map((e) => e.name).toList();
  }

  /// 모든 판매자 이름 가져오기
  Future<List<String>> getSellers() async {
    final rows = await (db.select(db.sellers)
          ..orderBy([
            (s) =>
                OrderingTerm(expression: s.displayOrder, mode: OrderingMode.asc)
          ]))
        .get();
    return rows.map((e) => e.name).toList();
  }

  /// 모든 카테고리 이름 가져오기
  Future<List<String>> getCategories() async {
    final rows = await (db.select(db.categories)
          ..orderBy([
            (c) =>
                OrderingTerm(expression: c.displayOrder, mode: OrderingMode.asc)
          ]))
        .get();
    return rows.map((e) => e.name).toList();
  }

  /// ★ 테마 순서 일괄 업데이트 (데이터가 없으면 INSERT하여 displayOrder 부여)
  Future<void> updateThemeOrders(List<String> themeNames) async {
    await db.transaction(() async {
      for (int i = 0; i < themeNames.length; i++) {
        final name = themeNames[i];
        final existing = await (db.select(db.themes)
              ..where((t) => t.name.equals(name)))
            .getSingleOrNull();

        if (existing != null) {
          await (db.update(db.themes)..where((t) => t.id.equals(existing.id)))
              .write(ThemesCompanion(displayOrder: Value(i)));
        } else {
          await db.into(db.themes).insert(
                ThemesCompanion.insert(
                  name: name,
                  displayOrder: Value(i),
                ),
              );
        }
      }
    });
  }

  /// ★ 카테고리 순서 일괄 업데이트
  Future<void> updateCategoryOrders(List<String> categoryNames) async {
    await db.transaction(() async {
      for (int i = 0; i < categoryNames.length; i++) {
        final name = categoryNames[i];
        final existing = await (db.select(db.categories)
              ..where((c) => c.name.equals(name)))
            .getSingleOrNull();

        if (existing != null) {
          await (db.update(db.categories)
                ..where((c) => c.id.equals(existing.id)))
              .write(CategoriesCompanion(displayOrder: Value(i)));
        } else {
          await db.into(db.categories).insert(
                CategoriesCompanion.insert(
                  name: name,
                  displayOrder: Value(i),
                ),
              );
        }
      }
    });
  }

  /// ★ 판매자 순서 일괄 업데이트
  Future<void> updateSellerOrders(List<String> sellerNames) async {
    await db.transaction(() async {
      for (int i = 0; i < sellerNames.length; i++) {
        final name = sellerNames[i];
        final existing = await (db.select(db.sellers)
              ..where((s) => s.name.equals(name)))
            .getSingleOrNull();

        if (existing != null) {
          await (db.update(db.sellers)..where((s) => s.id.equals(existing.id)))
              .write(SellersCompanion(displayOrder: Value(i)));
        } else {
          await db.into(db.sellers).insert(
                SellersCompanion.insert(
                  name: name,
                  displayOrder: Value(i),
                ),
              );
        }
      }
    });
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
