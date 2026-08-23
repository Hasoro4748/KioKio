import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/network/kiosk_network_discovery.dart';
import 'package:kiosk/network/kiosk_network_status.dart';

final kioskNetworkProvider =
    StateNotifierProvider<KioskNetworkDiscovery, KioskStatus>((ref) {
  return KioskNetworkDiscovery(ref)..init();
});
