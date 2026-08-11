import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/utils/kiosk_network_discovery.dart';
import 'package:kiosk/utils/kiosk_network_status.dart';
import 'package:kiosk/utils/pos_network_status.dart';

final kioskNetworkProvider =
    StateNotifierProvider<KioskNetworkDiscovery, KioskStatus>((ref) {
  return KioskNetworkDiscovery()..init();
});
