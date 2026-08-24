import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/db/dao/filter_dao.dart';
import 'package:kiosk/db/dao/image_dao.dart';
import 'package:kiosk/db/dao/product_dao.dart';
import 'package:kiosk/db/dao/relation_dao.dart';
import 'package:kiosk/db/repositories/product_repository.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/network/productSyncMessage.dart';

import 'package:kiosk/providers/database_provider.dart';
import 'package:kiosk/providers/pos_network_service_provider.dart';
import 'package:kiosk/providers/product_service_provider.dart';
import 'package:kiosk/sevices/product_service.dart';
import 'package:path/path.dart' as p;

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
    await _broadcastSync(SyncAction.create, [product]);
    await reload();
  }

  Future<void> updateProduct(ProductModel product) async {
    await _service.updateProduct(product);
    await _broadcastSync(SyncAction.update, [product]);
    await reload();
  }

  Future<void> deleteProduct(int id) async {
    final productToDelete = (state.value ?? []).firstWhere((p) => p.id == id);
    await _service.deleteProduct(id);
    await _broadcastSync(SyncAction.delete, [productToDelete]);
    await reload();
  }

  Future<void> _broadcastSync(
      SyncAction action, List<ProductModel> products) async {
    try {
      final posService = ref.read(posNetworkServiceProvider.notifier);
      Map<String, String> imageDatas = {};
      if (action != SyncAction.delete) {
        for (var product in products) {
          for (var img in product.images) {
            final file = File(img.imagePath);
            if (await file.exists()) {
              final fileName = p.basename(img.imagePath);
              final bytes = await file.readAsBytes();
              imageDatas[fileName] = base64Encode(bytes);
            }
          }
        }
      }

      posService.broadcastProductSync(
        ProductSyncMessage(
          action: action,
          products: products,
          imageDatas: imageDatas.isNotEmpty ? imageDatas : null, // 이미지 데이터 추가!
        ),
      );
    } catch (e) {
      print("동기화 브로드캐스트 실패: $e");
    }
  }

  void updateSyncManual(List<ProductModel> updatedProducts) {
    _broadcastSync(SyncAction.update, updatedProducts);
  }
}
