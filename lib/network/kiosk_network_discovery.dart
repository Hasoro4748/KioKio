import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_nsd/flutter_nsd.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/kiosk_setting_model.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/network/kiosk_network_status.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/providers/product_service_provider.dart';
import 'package:kiosk/providers/settings_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import 'package:path/path.dart' as p;

class KioskNetworkDiscovery extends StateNotifier<KioskStatus> {
  final Ref ref;
  KioskNetworkDiscovery(this.ref) : super(KioskStatus.idle);

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
    if (state == KioskStatus.connected) return;

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
      _channel = IOWebSocketChannel.connect(Uri.parse(url),
          pingInterval: const Duration(seconds: 5));

      state = KioskStatus.connected; // 여기서 상태 변경

      _channel!.stream.listen(
        (message) async {
          final data = jsonDecode(message as String);
          if (data['event'] == 'connection_confirmed') {
            print("POS 연결 성공! 서버 ID: ${data['sid']}");
            state = KioskStatus.connected;
            return;
          }
          if (data['type'] == 'PRODUCT_SYNC') {
            print("상품 동기화 메세지 수신");
            final productService = ref.read(productServiceProvider);

            await productService.syncProduct(data);

            ref.read(productProvider.notifier).reload();
            return;
          }
          if (data['type'] == 'KIOSK_SETTINGS_SYNC') {
            print("키오스크 신규 설정 수신");
            final settingsData = data['settings'];
            final imageDatas = data['imageDatas'] as Map<String, dynamic>?;

            String finalLogoPath = settingsData['logoPath'] ?? '';

            // 1. 로고 이미지 데이터가 포함되어 있다면 로컬에 저장
            if (imageDatas != null && imageDatas.isNotEmpty) {
              final appDir = await getApplicationDocumentsDirectory();
              final logoDir = Directory(p.join(appDir.path, 'config'));
              if (!await logoDir.exists())
                await logoDir.create(recursive: true);

              for (var entry in imageDatas.entries) {
                final bytes = base64Decode(entry.value);
                final file = File(p.join(logoDir.path, entry.key));
                await file.writeAsBytes(bytes);
                finalLogoPath = file.path; // 로컬 경로로 업데이트
                print("키오스크 로고 업데이트 완료: $finalLogoPath");
              }
            }

            // 2. SettingsProvider를 통해 상태 업데이트
            final model = KioskSettingsModel.fromJson(settingsData);
            // 이미지 파일이 저장되었다면 실제 로컬 경로로 덮어씌움
            final updatedModel = KioskSettingsModel(
              gridCount: model.gridCount,
              logoPath:
                  finalLogoPath.isNotEmpty ? finalLogoPath : model.logoPath,
              welcomeMessage: model.welcomeMessage,
              waitTime: model.waitTime,
              useIdleScreen: model.useIdleScreen,
            );

            await ref
                .read(settingsProvider.notifier)
                .updateKioskSettings(updatedModel);
            return;
          }

          // 디버그용
          print("Pos 수신 : $message");
        },
        onDone: () {
          print("연결 종료됨");
          state = KioskStatus.searching;
          _channel = null;
          Future.delayed(const Duration(seconds: 5), () {
            // 사용자가 수동으로 멈춘 게 아니라면 재탐색 실행
            if (state == KioskStatus.searching) {
              print("자동 재탐색 시작...");
              searchForPos();
            }
          });
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
