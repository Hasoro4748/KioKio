import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/providers/repository_provider.dart';
import 'package:kiosk/sevices/product_service.dart';

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(
    ref.watch(productRepositoryProvider),
  );
});
