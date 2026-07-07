import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/db/dao/filter_dao.dart';
import 'package:kiosk/db/dao/image_dao.dart';
import 'package:kiosk/db/dao/product_dao.dart';
import 'package:kiosk/db/dao/relation_dao.dart';
import 'package:kiosk/db/repositories/product_repository.dart';
import 'package:kiosk/models/product_model.dart';

import 'package:kiosk/providers/database_provider.dart';
import 'package:kiosk/providers/product_service_provider.dart';
import 'package:kiosk/sevices/product_service.dart';

final productProvider =
    AsyncNotifierProvider<ProductNotifier, List<ProductModel>>(
  ProductNotifier.new,
);

class ProductNotifier extends AsyncNotifier<List<ProductModel>> {
  ProductService get _service => ref.read(productServiceProvider);

  @override
  Future<List<ProductModel>> build() {
    return _service.loadProducts();
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => _service.loadProducts(),
    );
  }

  Future<void> addProduct(ProductModel product) async {
    await _service.addProduct(product);
    await reload();
  }

  Future<void> updateProduct(ProductModel product) async {
    await _service.updateProduct(product);
    await reload();
  }

  Future<void> deleteProduct(int id) async {
    await _service.deleteProduct(id);
    await reload();
  }
}
