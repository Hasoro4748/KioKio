import 'dart:async';
import 'dart:convert';

import 'package:flutter_nsd/flutter_nsd.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/utils/kiosk_network_status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class KioskNetworkDiscovery extends StateNotifier<KioskStatus> {
  KioskNetworkDiscovery() : super(KioskStatus.idle);

  final flutterNsd = FlutterNsd();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  void init() {
    _subscription = flutterNsd.stream.listen(
      (NsdServiceInfo serviceInfo) {
        // 핵심: 이미 연결 중이거나 연결된 상태면 무시
        if (state == KioskStatus.connected) return;

        if (serviceInfo.hostname != null && serviceInfo.port != null) {
          print(
              "Pos발견! IP: ${serviceInfo.hostname}, port: ${serviceInfo.port}");

          // 발견 즉시 탐색 중단 (연결 시도보다 먼저 수행하여 간섭 방지)
          stopDiscoveryService(onlyNsd: true);

          // 약간의 지연 후 연결 시도 (네이티브 리소스 안정화)
          _connectToPos(serviceInfo.hostname!, serviceInfo.port!);
        }
      },
      onError: (error) {
        print("NSD background 알림: $error");
      },
    );
  }

  Future<void> searchForPos() async {
    if (state == KioskStatus.searching || state == KioskStatus.connected)
      return;

    print("pos 탐색 시작");
    state = KioskStatus.searching; // 상태 업데이트

    try {
      await flutterNsd.discoverServices('_kiokio-pos._tcp.');
    } catch (e) {
      print("탐색 시작 실패 : $e");
      state = KioskStatus.error; // 상태 업데이트
    }
  }

  void _connectToPos(String host, int port) {
    final url = 'ws://$host:$port';
    print("Pos 접속 시도: $url");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      state = KioskStatus.connected; // 연결 성공 상태 업데이트

      _channel!.stream.listen(
        (message) {
          print("Pos 수신 : $message");
        },
        onDone: () {
          print("연결 종료됨");
          state = KioskStatus.idle;
          _channel = null;
        },
        onError: (e) {
          print("웹소켓 에러: $e");
          state = KioskStatus.error;
          _channel = null;
        },
      );
    } catch (e) {
      print("접속 실패: $e");
      state = KioskStatus.error;
    }
  }

  Future<void> stopDiscoveryService({bool onlyNsd = false}) async {
    try {
      // stopDiscovery는 에러가 자주 발생하므로 조용히 처리
      await flutterNsd.stopDiscovery();
    } catch (e) {
      print("NSD 중지 무시: $e");
    }

    if (!onlyNsd) {
      _channel?.sink.close();
      _channel = null;
      state = KioskStatus.idle;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  bool sendOrder(OrderModel order) {
    if (state == KioskStatus.connected && _channel != null) {
      try {
        final orderJson = jsonEncode(order.toJson());

        _channel!.sink.add(orderJson);
        print("Pos로 주문 전송 완료 : $orderJson");
        return true;
      } catch (e) {
        print("주문 전송 실패 : $e");
        return false;
      }
    } else {
      print("Pos 연결이 되어 있지 않아 전송을 할 수 없습니다.");
      return false;
    }
  }
}
