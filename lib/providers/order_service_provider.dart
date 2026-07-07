import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/providers/repository_provider.dart';
import 'package:kiosk/sevices/order_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(
    ref.watch(orderRepositoryProvider),
  );
});
