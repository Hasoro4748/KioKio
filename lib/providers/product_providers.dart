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
import 'package:kiosk/providers/dao_provider.dart';

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
    try {
      final updatedProducts = await _service.loadProducts();
      state = AsyncValue.data(updatedProducts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
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

  Future<void> updateProductOrders(List<ProductModel> reorderedProducts) async {
    // 1. DB에 새 순서 번호(0, 1, 2, ...) 일괄 반영
    await _service.updateProductOrders(reorderedProducts);

    // 2. POS의 메모리 데이터 새로고침
    await reload();

    // ★ 3. DB에서 새 순서 번호(0, 1, 2, ...)로 완전히 업데이트된 최신 목록을 가져옵니다.
    final updatedList = state.value ?? await _service.loadProducts();

    // ★ 4. 최신 displayOrder 수치를 가진 updatedList를 키오스크로 동기화 전송!
    await _broadcastSync(SyncAction.update, updatedList, includeImages: false);
  }

  /// 결제 시 재고 일괄 차감 (1번만 DB 반영 및 1번만 reload)
  Future<void> updateProductsStockBatch(Map<int, int> stockUpdates) async {
    await _service.updateStocksBatch(stockUpdates);
    await reload(); // 단 1번만 새로고침!
  }

  Future<void> deleteProduct(int id) async {
    final productToDelete = (state.value ?? []).firstWhere((p) => p.id == id);
    await _service.deleteProduct(id);
    await _broadcastSync(SyncAction.delete, [productToDelete]);
    await reload();
  }

  Future<void> _broadcastSync(SyncAction action, List<ProductModel> products,
      {bool includeImages = true}) async {
    try {
      final posService = ref.read(posNetworkServiceProvider.notifier);
      final filterDao = ref.read(filterDaoProvider);

      final themesOrder = await filterDao.getThemes();
      final categoriesOrder = await filterDao.getCategories();
      final sellersOrder = await filterDao.getSellers();

      Map<String, String> imageDatas = {};

      // ★ 신규 생성/수정 시에만 이미지 데이터를 포함하고, 순서 변경 시에는 대용량 이미지 제외
      if (includeImages && action != SyncAction.delete) {
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
          themesOrder: themesOrder,
          categoriesOrder: categoriesOrder,
          sellersOrder: sellersOrder,
          imageDatas: imageDatas.isNotEmpty ? imageDatas : null,
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
