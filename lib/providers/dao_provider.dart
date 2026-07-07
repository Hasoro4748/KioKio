import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/db/dao/filter_dao.dart';
import 'package:kiosk/db/dao/image_dao.dart';
import 'package:kiosk/db/dao/order_dao.dart';
import 'package:kiosk/db/dao/order_item_dao.dart';
import 'package:kiosk/db/dao/product_dao.dart';
import 'package:kiosk/db/dao/relation_dao.dart';
import 'package:kiosk/providers/database_provider.dart';

final orderDaoProvider = Provider<OrderDao>((ref) {
  final db = ref.watch(databaseProvider);
  return OrderDao(db);
});

final orderItemDaoProvider = Provider<OrderItemDao>((ref) {
  final db = ref.watch(databaseProvider);
  return OrderItemDao(db);
});

final productDaoProvider = Provider<ProductDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductDao(db);
});

final relationDaoProvider = Provider<RelationDao>((ref) {
  final db = ref.watch(databaseProvider);
  return RelationDao(db);
});

final imageDaoProvider = Provider<ImageDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ImageDao(db);
});

final filterDaoProvider = Provider<FilterDao>((ref) {
  final db = ref.watch(databaseProvider);
  return FilterDao(db);
});
