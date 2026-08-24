import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferences _prefs;
  SettingsService(this._prefs);

  static const String _keyProductManageGridCount = 'product_manage_count';
  static const String _keyKioskGridCount = 'kiosk_grid_count';
  static const String _keyKioskLogo = 'kiosk_logo_path';
  static const String _keyKioskWaitTime = 'kiosk_wait_time';
  static const String _keyKioskWelcome = 'kiosk_welcome_msg';
  static const String _keyUseIdle = 'use_kiosk_idle';

  Future<void> setProductManageGridCount(int count) async {
    await _prefs.setInt(_keyProductManageGridCount, count);
  }

  int getProductManageGridCount(int defaultValue) {
    return _prefs.getInt(_keyProductManageGridCount) ?? defaultValue;
  }

  Future<void> setKioskGridCount(int count) async {
    await _prefs.setInt(_keyKioskGridCount, count);
  }

  int getKioskGridCount(int defaultValue) {
    return _prefs.getInt(_keyKioskGridCount) ?? defaultValue;
  }

  Future<void> setKioskLogoPath(String path) async {
    await _prefs.setString(_keyKioskLogo, path);
  }

  String getKioskLogoPath(String defaultValue) {
    return _prefs.getString(_keyKioskLogo) ?? defaultValue;
  }

  Future<void> setKioskWaitTime(int time) async {
    await _prefs.setInt(_keyKioskWaitTime, time);
  }

  int getKioskWaitTime(int defaultValue) {
    return _prefs.getInt(_keyKioskWaitTime) ?? defaultValue;
  }

  Future<void> setKioskWelcomeMessage(String message) async {
    await _prefs.setString(_keyKioskWelcome, message);
  }

  String getKioskWelcomeMessage(String defaultValue) {
    return _prefs.getString(_keyKioskWelcome) ?? defaultValue;
  }

  Future<void> setUseKioskIdleScreen(bool use) async {
    await _prefs.setBool(_keyUseIdle, use);
  }

  bool getUseKioskIdleScreen(bool defaultValue) {
    return _prefs.getBool(_keyUseIdle) ?? defaultValue;
  }
}
