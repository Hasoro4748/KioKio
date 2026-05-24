import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:path_provider/path_provider.dart';

class ProductService {
  static Future<List<Product>> loadProducts() async {
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
