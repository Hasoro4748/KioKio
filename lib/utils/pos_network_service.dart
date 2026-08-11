import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/utils/pos_network_status.dart';

class PosNetworkService extends StateNotifier<PosNetworkState> {
  PosNetworkService(this.ref)
      : super(PosNetworkState(status: PosBroadcastStatus.idle));
  BonsoirBroadcast? _broadcast;
  HttpServer? _server;
  final Set<WebSocketChannel> _clients = {};
  final Ref ref;

  Future<void> startBroadcast() async {
    if (state.status == PosBroadcastStatus.broadcasting) return;

    // 상태 웹소캣
    state = state.copyWith(status: PosBroadcastStatus.starting);

    try {
      var handler = webSocketHandler(
        (WebSocketChannel webSocket) {
          _clients.add(webSocket);
          _updateConnectionCount();

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

      _server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
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

      // 서버 종료
      await _server?.close(force: true);
      _server = null;
    } catch (e) {
      print("서버 중단 중 실패 발생 : $e");
    } finally {
      _clients.clear();
      state = PosNetworkState(status: PosBroadcastStatus.idle);
      print("POS 서비스 중단 완료");
    }
  }
}
