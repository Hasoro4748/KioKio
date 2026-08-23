import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/network/pos_network_service.dart';
import 'package:kiosk/network/pos_network_status.dart';

final posNetworkServiceProvider =
    StateNotifierProvider<PosNetworkService, PosNetworkState>((ref) {
  return PosNetworkService(ref);
});
