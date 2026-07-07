import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/db/repositories/product_repository.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:path_provider/path_provider.dart';

class ProductService {
  final ProductRepository repository;

  ProductService(this.repository);

  Future<List<ProductModel>> loadProducts() async {
    return repository.getProducts();
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
