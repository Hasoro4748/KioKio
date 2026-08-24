import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:kiosk/models/kiosk_setting_model.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/network/pos_network_status.dart';
import 'package:kiosk/network/productSyncMessage.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class PosNetworkService extends StateNotifier<PosNetworkState> {
  PosNetworkService(this.ref)
      : super(PosNetworkState(status: PosBroadcastStatus.idle));
  BonsoirBroadcast? _broadcast;
  HttpServer? _server;
  final Set<WebSocketChannel> _clients = {};
  final Ref ref;

  Future<void> startBroadcast() async {
    if (state.status == PosBroadcastStatus.broadcasting ||
        state.status == PosBroadcastStatus.starting) return;

    // 2. 새로운 서버를 열기 전에 기존에 남아있을 수 있는 자원을 완전히 정리
    await stopBroadcast();

    state = state.copyWith(status: PosBroadcastStatus.starting);

    if (state.status == PosBroadcastStatus.broadcasting) return;

    // 상태 웹소캣
    state = state.copyWith(status: PosBroadcastStatus.starting);

    try {
      var handler = webSocketHandler(
        (WebSocketChannel webSocket) {
          _clients.add(webSocket);
          _updateConnectionCount();

          final welcomeMessage = jsonEncode({'event': 'connection_confirmed'});
          webSocket.sink.add(welcomeMessage);

          webSocket.stream.listen((message) {
            try {
              final Map<String, dynamic> data = jsonDecode(message as String);
              final receivedOrder = OrderModel.fromJson(data);
              print("새로운 주문 수신: ${receivedOrder.items.length}개 항목");
              ref.read(orderProvider.notifier).addOrder(receivedOrder);
            } catch (e) {
              print("주문 데이터 파싱 실패");
            }
          }, onDone: () {
            _clients.remove(webSocket);
            _updateConnectionCount();
          }, onError: (e) {
            _clients.remove(webSocket);
            _updateConnectionCount();
          });
        },
      );

      _server =
          await io.serve(handler, InternetAddress.anyIPv4, 8080, shared: true);
      print("웹소켓 서버 실행 중: ws://${_server!.address.address}:${_server!.port}");

      BonsoirService service = BonsoirService(
          name: 'KioKio-Pos-${DateTime.now().millisecondsSinceEpoch}',
          type: '_kiokio-pos._tcp',
          port: 8080);
      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.ready;
      await _broadcast!.start();

      print("브로드캐스트 시작됨: ${service.toJson()}");

      state = state.copyWith(status: PosBroadcastStatus.broadcasting);
      print("Pos 서비스 등록 완료");
    } catch (e) {
      print("서버 시작 오류 : $e");
      state = state.copyWith(status: PosBroadcastStatus.error);
    }
  }

  void _updateConnectionCount() {
    state = state.copyWith(connectKiosks: _clients.length);
  }

  Future<void> stopBroadcast() async {
    try {
      // bonsoir 등록 해제
      if (_broadcast != null) {
        await _broadcast!.stop();
        _broadcast = null;
      }
      if (_clients.isNotEmpty) {
        print("연결된 클라이언트 ${_clients.length}개 종료 중...");
        // 복사본을 만들어 순회하며 닫기
        final clientsToClose = List.from(_clients);
        for (var client in clientsToClose) {
          try {
            await client.sink.close();
          } catch (e) {
            print("소켓 닫기 오류: $e");
          }
        }
        _clients.clear();
      }
      // 3. HttpServer 종료 (force: true 필수)
      if (_server != null) {
        await _server!.close(force: true);
        _server = null;
        print("HttpServer 종료됨");
      }
    } catch (e) {
      print("서버 중단 중 실패 발생 : $e");
    } finally {
      _clients.clear();
      state = PosNetworkState(status: PosBroadcastStatus.idle);
      _updateConnectionCount();
      print("POS 서비스 중단 완료");
    }
  }

  // 상품 동기화 메시지 전송
  void broadcastProductSync(ProductSyncMessage message) {
    final jsonMessage = jsonEncode(message.toJson());
    for (var client in _clients) {
      try {
        client.sink.add(jsonMessage);
      } catch (e) {
        print("클라이언트 전송 실패: $e");
      }
    }
  }

  Future<void> syncAllProducts() async {
    try {
      final currentProducts = ref.read(productProvider).value ?? [];
      Map<String, String> imageDatas = {};
      if (currentProducts.isEmpty) {
        print("동기화할 상품이 없습니다.");
        return;
      }

      for (var product in currentProducts) {
        for (var image in product.images) {
          final file = File(image.imagePath);
          if (await file.exists()) {
            final fileName = p.basename(image.imagePath);
            final bytes = await file.readAsBytes();
            imageDatas[fileName] = base64Encode(bytes);
          }
        }
      }

      final syncMessage = ProductSyncMessage(
          action: SyncAction.initial,
          products: currentProducts,
          imageDatas: imageDatas);

      broadcastProductSync(syncMessage);
      print("모든 클라이언트에게 ${currentProducts.length}개의 상품 동기화 메시지 전송");
    } catch (e) {
      print("전체 동기화 전송 실패: $e");
    }
  }

  void broadcastKioskSettings(KioskSettingsModel settings,
      {Map<String, String>? imageDatas}) {
    final message = {
      'type': 'KIOSK_SETTINGS_SYNC',
      'settings': settings.toJson(),
      'imageDatas': imageDatas, // 로고 이미지 파일 포함 (Base64)
      'timestamp': DateTime.now().toIso8601String(),
    };

    final jsonMessage = jsonEncode(message);
    for (var client in _clients) {
      client.sink.add(jsonMessage);
    }
    print("키오스크 설정 동기화 메시지 전송 완료");
  }
}
