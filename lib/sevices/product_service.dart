import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/db/repositories/product_repository.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class ProductService {
  final ProductRepository repository;

  ProductService(this.repository);

  Future<List<ProductModel>> loadProducts() async {
    return repository.getProducts();
  }

  /// 동기화 받기 메소드
  /// 동기화 받기 메소드 (진행 상황 콜백 onProgress 추가)
  Future<void> syncProduct(
    Map<String, dynamic> json,
    String serverIp, {
    void Function(int current, int total, String message)? onProgress,
  }) async {
    final action = json['action'];
    final productsJson = json['products'] as List;

    final appDir = await getApplicationDocumentsDirectory();
    final localImageDir = Directory(p.join(appDir.path, 'product_images'));

    if (!await localImageDir.exists()) {
      await localImageDir.create(recursive: true);
    }

    // 1. 전체 이미지 수 계산
    int totalImages = 0;
    for (var productMap in productsJson) {
      final product = ProductModel.fromJson(productMap);
      totalImages += product.images.length;
    }

    onProgress?.call(0, totalImages > 0 ? totalImages : 1, "동기화 준비 중...");

    int processedImages = 0;
    for (var productMap in productsJson) {
      final product = ProductModel.fromJson(productMap);

      for (var img in product.images) {
        processedImages++;
        final fileName = p.basename(img.imagePath);
        final localPath = p.join(localImageDir.path, fileName);
        final file = File(localPath);

        bool needDownload = !await file.exists();
        if (!needDownload) {
          try {
            needDownload = (await file.length()) == 0;
          } catch (_) {
            needDownload = true;
          }
        }

        if (needDownload) {
          try {
            onProgress?.call(
              processedImages,
              totalImages,
              "이미지 다운로드 중 ($processedImages/$totalImages)...",
            );
            final response = await http
                .get(Uri.parse("http://$serverIp:8080/images/$fileName"));
            if (response.statusCode == 200) {
              await file.writeAsBytes(response.bodyBytes);
            }
          } catch (e) {
            print("이미지 다운로드 에러 ($fileName): $e");
          }
        } else {
          onProgress?.call(
            processedImages,
            totalImages,
            "이미지 확인 완료 ($processedImages/$totalImages)",
          );
        }
      }
    }

    onProgress?.call(totalImages, totalImages, "상품 데이터베이스 저장 중...");

    if (action == 'initial') {
      await repository.clearAllProducts();
    }
    if (json['themesOrder'] != null) {
      await repository.filterDao
          .updateThemeOrders(List<String>.from(json['themesOrder']));
    }
    if (json['categoriesOrder'] != null) {
      await repository.filterDao
          .updateCategoryOrders(List<String>.from(json['categoriesOrder']));
    }
    if (json['sellersOrder'] != null) {
      await repository.filterDao
          .updateSellerOrders(List<String>.from(json['sellersOrder']));
    }

    for (var productMap in productsJson) {
      final product = ProductModel.fromJson(productMap);

      final localImages = product.images.map((img) {
        final fileName = p.basename(img.imagePath);
        return img.copyWith(imagePath: p.join(localImageDir.path, fileName));
      }).toList();
      final localProduct = product.copyWith(images: localImages);

      switch (action) {
        case 'initial':
        case 'create':
          await repository.addProduct(localProduct);
          break;
        case 'update':
          await repository.updateProduct(localProduct);
          break;
        case 'delete':
          await repository.deleteProduct(product.id);
          break;
      }
    }

    onProgress?.call(totalImages, totalImages, "동기화 완료!");
  }

  Future<void> addProduct(ProductModel product) async {
    return repository.addProduct(product);
  }

  Future<void> updateProduct(ProductModel product) {
    return repository.updateProduct(product);
  }

  Future<void> updateStocksBatch(Map<int, int> stockUpdates) async {
    return repository.updateStocksBatch(stockUpdates);
  }

  Future<void> updateProductOrders(List<ProductModel> products) async {
    return repository.updateProductOrders(products);
  }

  Future<void> deleteProduct(int productId) {
    return repository.deleteProduct(productId);
  }

  Future<ProductModel> getProductDetail(int productId) async {
    return repository.getProductDetail(productId);
  }

  static Future<List<Product>> loadLocalProducts() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/files/products.json');

    if (!await file.exists()) {
      final folder = Directory(file.parent.path);

      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final jsonString =
          await rootBundle.loadString('assets/files/products.json');

      await file.writeAsString(jsonString);
    }

    final jsonString = await file.readAsString();
    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList.map((e) => Product.fromJson(e)).toList();
  }

  static saveProducts(List<Product> state) {}
}
