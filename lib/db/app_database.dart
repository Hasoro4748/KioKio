import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/products.dart';
import 'tables/product_images.dart';
part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    ProductImages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(productImages);
          }
        },
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
        /// 1. 상품 저장
        final productId = await into(products).insert(
          ProductsCompanion.insert(
            name: item['name'],
            theme: item['theme'],
            seller: item['seller'],
            categoryGroup: item['categoryGroup'],
            basePrice: item['basePrice'],
            description: item['description'],
            stock: Value(item['stock']),
            isAvailable: Value(item['isAvailable']),
            createdAt: DateTime.parse(
              item['createdAt'],
            ),
            updatedAt: DateTime.parse(
              item['updatedAt'],
            ),
          ),
        );

        /// 2. 이미지 저장
        final List<dynamic> images = item['images'] ?? [];

        for (int i = 0; i < images.length; i++) {
          await into(productImages).insert(
            ProductImagesCompanion.insert(
              productId: productId,
              imagePath: images[i],
              sortOrder: Value(i),
              isThumbnail: Value(i == 0),
              createdAt: DateTime.now(),
            ),
          );
        }
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
