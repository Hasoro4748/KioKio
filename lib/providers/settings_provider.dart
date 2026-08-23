import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  SettingsNotifier(this._service)
      : super(AppSettings(productManageGridCount: 0)) {
    _loadSettings();
  }
  void _loadSettings() {
    final count = _service.getProductManageGridCount(0);
    state = AppSettings(productManageGridCount: count);
  }

  Future<void> updateProductGridCount(int count) async {
    await _service.setProductManageGridCount(count);
    state = state.copyWith(productManageGridCount: count);
  }
}

class AppSettings {
  final int productManageGridCount;
  AppSettings({required this.productManageGridCount});

  AppSettings copyWith({int? productManageGridCount}) {
    return AppSettings(
      productManageGridCount:
          productManageGridCount ?? this.productManageGridCount,
    );
  }
}
