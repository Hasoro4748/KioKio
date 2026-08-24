import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/kiosk_setting_model.dart';
import 'package:kiosk/sevices/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.read(settingsServiceProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(_initialState()) {
    _loadSettings();
  }

  // 초기 더미 상태
  static AppSettings _initialState() => AppSettings(
        productManageGridCount: 7,
        kioskGridCount: 3,
        kioskLogoPath: '',
        kioskWelcomeMessage: '터치하여 주문을 시작하세요',
        kioskWaitTime: 15,
        useKioskIdleScreen: true,
      );

  // 로컬 저장소에서 데이터 로드
  void _loadSettings() {
    state = AppSettings(
      productManageGridCount: _service.getProductManageGridCount(7),
      kioskGridCount: _service.getKioskGridCount(3),
      kioskLogoPath: _service.getKioskLogoPath(''),
      kioskWaitTime: _service.getKioskWaitTime(15),
      kioskWelcomeMessage: _service.getKioskWelcomeMessage('터치하여 주문을 시작하세요'),
      useKioskIdleScreen: _service.getUseKioskIdleScreen(true),
    );
  }

  // POS로부터 받은 전체 키오스크 설정을 업데이트 (동기화 용)
  Future<void> updateKioskSettings(KioskSettingsModel settings) async {
    await _service.setKioskGridCount(settings.gridCount);
    await _service.setKioskLogoPath(settings.logoPath);
    await _service.setKioskWaitTime(settings.waitTime);
    await _service.setKioskWelcomeMessage(settings.welcomeMessage);
    await _service.setUseKioskIdleScreen(settings.useIdleScreen);

    state = state.copyWith(
      kioskGridCount: settings.gridCount,
      kioskLogoPath: settings.logoPath,
      kioskWaitTime: settings.waitTime,
      kioskWelcomeMessage: settings.welcomeMessage,
      useKioskIdleScreen: settings.useIdleScreen,
    );
  }

  // 개별 설정 변경 메서드들 (필요시 추가)
  Future<void> updateProductManageGridCount(int count) async {
    await _service.setProductManageGridCount(count);
    state = state.copyWith(productManageGridCount: count);
  }
}

class AppSettings {
  final int productManageGridCount; // POS용
  final int kioskGridCount; // 키오스크용
  final String kioskLogoPath;
  final String kioskWelcomeMessage;
  final int kioskWaitTime;
  final bool useKioskIdleScreen;

  AppSettings({
    required this.productManageGridCount,
    required this.kioskGridCount,
    required this.kioskLogoPath,
    required this.kioskWelcomeMessage,
    required this.kioskWaitTime,
    required this.useKioskIdleScreen,
  });

  // 모든 필드를 포함한 copyWith
  AppSettings copyWith({
    int? productManageGridCount,
    int? kioskGridCount,
    String? kioskLogoPath,
    String? kioskWelcomeMessage,
    int? kioskWaitTime,
    bool? useKioskIdleScreen,
  }) {
    return AppSettings(
      productManageGridCount:
          productManageGridCount ?? this.productManageGridCount,
      kioskGridCount: kioskGridCount ?? this.kioskGridCount,
      kioskLogoPath: kioskLogoPath ?? this.kioskLogoPath,
      kioskWelcomeMessage: kioskWelcomeMessage ?? this.kioskWelcomeMessage,
      kioskWaitTime: kioskWaitTime ?? this.kioskWaitTime,
      useKioskIdleScreen: useKioskIdleScreen ?? this.useKioskIdleScreen,
    );
  }
}
