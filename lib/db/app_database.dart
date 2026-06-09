import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/products.dart';
import 'tables/product_images.dart';
import 'tables/categories.dart';
import 'tables/sellers.dart';
import 'tables/themes.dart';
import 'tables/product_categories.dart';
import 'tables/product_sellers.dart';
import 'tables/product_themes.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    ProductImages,
    Themes,
    Sellers,
    Categories,
    ProductThemes,
    ProductSellers,
    ProductCategories,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
      );

  Future<void> seedProducts() async {
    final existing = await select(products).get();

    /// 이미 데이터 있으면 종료
    if (existing.isNotEmpty) return;

    final jsonString = await rootBundle.loadString(
      'assets/json/products_seed.json',
    );

    final List<dynamic> jsonList = jsonDecode(jsonString);

    await transaction(() async {
      for (final item in jsonList) {
        final productId = await into(products).insert(
          ProductsCompanion.insert(
            name: item['name'],
            basePrice: item['basePrice'],
            description: item['description'],
            stock: Value(item['stock']),
            isAvailable: Value(item['isAvailable']),
            createdAt: DateTime.parse(item['createdAt']),
            updatedAt: DateTime.parse(item['updatedAt']),
          ),
        );

        /// images
        final images = item['images'] as List<dynamic>? ?? [];

        await batch((batch) {
          batch.insertAll(
            productImages,
            images.asMap().entries.map((e) {
              return ProductImagesCompanion.insert(
                productId: productId,
                imagePath: e.value,
                sortOrder: Value(e.key),
                isThumbnail: Value(e.key == 0),
                createdAt: DateTime.now(),
              );
            }).toList(),
          );
        });

        //themes
        final themesJson = item['themes'] as List<dynamic>? ?? [];
        for (final themeName in themesJson) {
          final existingTheme = await (select(themes)
                ..where((t) => t.name.equals(themeName)))
              .getSingleOrNull();

          //중복 체크
          final themeId = existingTheme?.id ??
              await into(themes).insert(
                ThemesCompanion.insert(name: themeName, imagePath: "null"),
              );

          await into(productThemes).insert(
            ProductThemesCompanion.insert(
                productId: productId, themeId: themeId),
          );
        }

        //sellers
        final sellersJson = item['sellers'] as List<dynamic>? ?? [];
        for (final sellerName in sellersJson) {
          final existingSeller = await (select(sellers)
                ..where((s) => s.name.equals(sellerName)))
              .getSingleOrNull();

          final sellerId = existingSeller?.id ??
              await into(sellers).insert(
                SellersCompanion.insert(
                  name: sellerName,
                ),
              );

          await into(productSellers).insert(
            ProductSellersCompanion.insert(
              productId: productId,
              sellerId: sellerId,
            ),
          );
        }

        //categories
        final categoriesJson = item['categories'] as List<dynamic>? ?? [];
        for (final categoryName in categoriesJson) {
          final existingCategory = await (select(categories)
                ..where((c) => c.name.equals(categoryName)))
              .getSingleOrNull();

          final categoryId = existingCategory?.id ??
              await into(categories).insert(
                CategoriesCompanion.insert(
                  name: categoryName,
                ),
              );

          await into(productCategories).insert(
            ProductCategoriesCompanion.insert(
              productId: productId,
              categoryId: categoryId,
            ),
          );
        }
      }
    });
  }

  Future<void> resetProducts() async {
    await delete(productThemes).go();
    await delete(productSellers).go();
    await delete(productCategories).go();

    await delete(productImages).go();

    await delete(themes).go();
    await delete(sellers).go();
    await delete(categories).go();

    await delete(products).go();

    await seedProducts();

    // //디버깅 용
    // final themesList = await select(themes).get();
    // final themesTmpList = await select(productThemes).get();
    // print(themesList);
    // print(themesTmpList);
    //
    // final sellerList = await select(categories).get();
    // print(sellerList);
    //
    // final cateList = await select(sellers).get();
    // print(cateList);
    //삭제 요망
  }
}

/// =========================
/// DB Connection
/// =========================
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      p.join(dir.path, 'kiokio.sqlite'),
    );

    return NativeDatabase.createInBackground(file);
  });
}
