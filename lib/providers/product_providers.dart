import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/db/repositories/product_repository.dart';
import 'package:kiosk/models/product_model.dart';

import 'package:kiosk/providers/database_provider.dart';

final productProvider =
    StateNotifierProvider<ProductNotifier, List<ProductModel>>((ref) {
  final db = ref.watch(databaseProvider);

  return ProductNotifier(
    ProductRepository(db),
  );
});

class ProductNotifier extends StateNotifier<List<ProductModel>> {
  final ProductRepository repository;
  ProductNotifier(this.repository) : super([]) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = await repository.getProducts();
  }

  Future<void> addProduct(ProductModel product) async {
    await repository.addProduct(product);

    await loadProducts();
  }

  Future<void> updateProduct(ProductModel product) async {
    await repository.updateProduct(product);

    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await repository.deleteProduct(id);

    await loadProducts();
  }
}
