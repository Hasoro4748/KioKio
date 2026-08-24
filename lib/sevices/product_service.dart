import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/db/repositories/product_repository.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ProductService {
  final ProductRepository repository;

  ProductService(this.repository);

  Future<List<ProductModel>> loadProducts() async {
    return repository.getProducts();
  }

  /// 동기화 받기 메소드
  Future<void> syncProduct(Map<String, dynamic> json) async {
    final action = json['action']; // 'create', 'update', 'delete'
    final productsJson = json['products'] as List;
    final imageDatas = json['imageDatas'] as Map<String, dynamic>?;

    final appDir = await getApplicationDocumentsDirectory();
    final localImageDir = Directory(p.join(appDir.path, 'product_images'));
    // 이미지 디렉토리가 없으면 생성
    if (!await localImageDir.exists())
      await localImageDir.create(recursive: true);

    if (imageDatas != null) {
      for (var entry in imageDatas.entries) {
        final fileName = entry.key;
        final base64Data = entry.value as String;
        final localPath = p.join(localImageDir.path, fileName);
        final file = File(localPath);

        if (!await file.exists()) {
          final bytes = base64Decode(base64Data);
          await file.writeAsBytes(bytes);
          print("이미지 저장 완료: $localPath");
        }
      }
    }

    //초기 동기화일시 기존 데이터 삭제
    if (action == 'initial') {
      await repository.clearAllProducts();
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
          await repository
              .updateProduct(localProduct); // ◀ 수정됨: localProduct 사용
          break;
        case 'delete':
          await repository.deleteProduct(product.id);
          break;
      }
    }
  }

  Future<void> addProduct(ProductModel product) async {
    return repository.addProduct(product);
  }

  Future<void> updateProduct(ProductModel product) {
    return repository.updateProduct(product);
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
