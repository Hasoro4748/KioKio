import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/db/repositories/OrderRepository.dart';
import 'package:kiosk/db/repositories/product_repository.dart';
import 'package:kiosk/providers/dao_provider.dart';
import 'package:kiosk/providers/database_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(
      db: ref.watch(databaseProvider),
      orderDao: ref.watch(orderDaoProvider),
      orderItemDao: ref.watch(orderItemDaoProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
      db: ref.watch(databaseProvider),
      productDao: ref.watch(productDaoProvider),
      imageDao: ref.watch(imageDaoProvider),
      filterDao: ref.watch(filterDaoProvider),
      relationDao: ref.watch(relationDaoProvider));
});
