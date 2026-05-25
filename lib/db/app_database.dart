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

        /// TODO: relation tables
        // theme / seller / category
      }
    });
  }

  Future<void> resetProducts() async {
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
