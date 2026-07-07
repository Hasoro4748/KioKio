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

import 'tables/orders.dart';
import 'tables/order_items.dart';

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
    Orders,
    OrderItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      beforeOpen: (details) async {},
      onUpgrade: (m, from, to) async {
        if (from < 3) {
          await m.createTable(orders);
          await m.createTable(orderItems);
        }
      });

  Future<void> seedProducts() async {
    final existing = await select(products).get();

    /// 이미 데이터 있으면 종료
    if (existing.isNotEmpty) return;

    /// 경로 확보
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(appDir.path, 'product_images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

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

        /// images 처리: Assets -> Local File System 복사
        final images = item['images'] as List<dynamic>? ?? [];

        for (int i = 0; i < images.length; i++) {
          final String assetPath = images[i];
          final String fileName = p.basename(assetPath); // 파일명 추출
          final String localPath = p.join(imageDir.path, fileName);
          final File localFile = File(localPath);

          // Asset 파일을 Byte로 읽어서 로컬 파일로 쓰기
          try {
            final ByteData data = await rootBundle.load(assetPath);
            final List<int> bytes =
                data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
            await localFile.writeAsBytes(bytes);

            // DB에는 로컬 경로 저장
            await into(productImages).insert(
              ProductImagesCompanion.insert(
                productId: productId,
                imagePath: localPath, // 로컬 경로 저장
                sortOrder: Value(i),
                isThumbnail: Value(i == 0),
                createdAt: DateTime.now(),
              ),
            );
          } catch (e) {
            print("이미지 복사 실패 ($assetPath): $e");
            // 실패 시 에셋 경로라도 저장하거나 스킵
          }
        }

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
