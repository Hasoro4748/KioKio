// lib/network/kiosk_network_discovery.dart 전체 수정

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_nsd/flutter_nsd.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/kiosk_setting_model.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/network/kiosk_network_status.dart';
import 'package:kiosk/providers/dao_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/providers/product_service_provider.dart';
import 'package:kiosk/providers/settings_provider.dart';
import 'package:kiosk/providers/sync_progress_provider.dart';
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

  bool _isConnecting = false; // ★ 중복 연결 차단용 플래그 추가

  void init() {
    _subscription = flutterNsd.stream.listen(
      (NsdServiceInfo serviceInfo) {
        // ★ 이미 연결되었거나, 연결 진행 중이면 연달아 들어오는 탐색 신호 무시
        if (state == KioskStatus.connected || _isConnecting) return;

        if (serviceInfo.hostname != null && serviceInfo.port != null) {
          print(
              "Pos발견! IP: ${serviceInfo.hostname}, port: ${serviceInfo.port}");

          stopDiscoveryService(onlyNsd: true);
          _connectToPos(serviceInfo.hostname!, serviceInfo.port!);
        }
      },
      onError: (error) {
        print("NSD background 알림: $error");
      },
    );
  }

  Future<void> searchForPos() async {
    if (state == KioskStatus.connected || _isConnecting) return;

    print("pos 탐색 시작");
    state = KioskStatus.searching;

    try {
      await flutterNsd.discoverServices('_kiokio-pos._tcp.');
    } catch (e) {
      print("탐색 시작 실패 : $e");
      state = KioskStatus.error;
    }
  }

  void _connectToPos(String host, int port) {
    // ★ 중복 접속 요청 방지
    if (state == KioskStatus.connected || _isConnecting) return;

    _isConnecting = true; // 연결 시도 플래그 ON

    // 기존 소켓 채널이 존재한다면 깨끗이 닫고 시작
    _channel?.sink.close();
    _channel = null;

    final url = 'ws://$host:$port';
    print("Pos 접속 시도: $url");

    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(url),
          pingInterval: const Duration(seconds: 5));

      _channel!.stream.listen(
        (message) async {
          final data = jsonDecode(message as String);

          if (data['event'] == 'connection_confirmed') {
            print("POS 연결 성공! 서버 ID: ${data['sid']}");
            state = KioskStatus.connected;
            _isConnecting = false; // ★ 연결 완료
            return;
          }
          if (data['type'] == 'PRODUCT_SYNC') {
            print("상품 동기화 메세지 수신");
            final productService = ref.read(productServiceProvider);
            final syncNotifier = ref.read(syncProgressProvider.notifier);

            final isInitial = data['action'] == 'initial';

            await productService.syncProduct(
              data,
              host,
              onProgress: (current, total, message) {
                if (isInitial) {
                  if (current == 0) {
                    syncNotifier.startSync(total, message);
                  } else if (current >= total && message == '동기화 완료!') {
                    syncNotifier.completeSync(message);
                  } else {
                    syncNotifier.updateProgress(current, message);
                  }
                }
              },
            );
            ref.invalidate(orderedThemesProvider);
            ref.invalidate(orderedSellersProvider);
            ref.invalidate(orderedCategoriesProvider);
            await ref.read(productProvider.notifier).reload();

            return;
          }
          if (data['type'] == 'KIOSK_SETTINGS_SYNC') {
            print("키오스크 신규 설정 수신");
            final settingsData = data['settings'];
            final imageDatas = data['imageDatas'] as Map<String, dynamic>?;

            String finalLogoPath = settingsData['logoPath'] ?? '';

            if (imageDatas != null && imageDatas.isNotEmpty) {
              final appDir = await getApplicationDocumentsDirectory();
              final logoDir = Directory(p.join(appDir.path, 'config'));
              if (!await logoDir.exists())
                await logoDir.create(recursive: true);

              for (var entry in imageDatas.entries) {
                final bytes = base64Decode(entry.value);
                final file = File(p.join(logoDir.path, entry.key));
                await file.writeAsBytes(bytes);
                finalLogoPath = file.path;
                print("키오스크 로고 업데이트 완료: $finalLogoPath");
              }
            }

            final model = KioskSettingsModel.fromJson(settingsData);
            final updatedModel = KioskSettingsModel(
              gridCount: model.gridCount,
              logoPath:
                  finalLogoPath.isNotEmpty ? finalLogoPath : model.logoPath,
              welcomeMessage: model.welcomeMessage,
              waitTime: model.waitTime,
              useIdleScreen: model.useIdleScreen,
              idleMode: model.idleMode, // ★ 키오스크 수신 시 idleMode 적용!
            );

            await ref
                .read(settingsProvider.notifier)
                .updateKioskSettings(updatedModel);
            return;
          }

          print("Pos 수신 : $message");
        },
        onDone: () {
          print("연결 종료됨");
          state = KioskStatus.searching;
          _isConnecting = false;
          _channel = null;
          Future.delayed(const Duration(seconds: 1), () {
            if (state == KioskStatus.searching && !_isConnecting) {
              print("자동 재탐색 시작...");
              searchForPos();
            }
          });
        },
        onError: (e) {
          print("웹소켓 에러: $e");
          state = KioskStatus.searching;
          _isConnecting = false;
          _channel = null;
        },
      );
    } catch (e) {
      print("접속 실패: $e");
      state = KioskStatus.searching;
      _isConnecting = false;
    }
  }

  Future<void> stopDiscoveryService({bool onlyNsd = false}) async {
    try {
      await flutterNsd.stopDiscovery();
    } catch (e) {
      print("NSD 중지 무시: $e");
    }

    if (!onlyNsd) {
      _channel?.sink.close();
      _channel = null;
      _isConnecting = false;
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
        final orderPayload = {
          'type': 'NEW_ORDER',
          'order': order.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        };
        final orderJson = jsonEncode(orderPayload);

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
