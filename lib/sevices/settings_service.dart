import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferences _prefs;
  SettingsService(this._prefs);

  static const String _keyProductManageGridCount = 'product_manage_count';

  Future<void> setProductManageGridCount(int count) async {
    await _prefs.setInt(_keyProductManageGridCount, count);
  }

  int getProductManageGridCount(int defaultValue) {
    return _prefs.getInt(_keyProductManageGridCount) ?? defaultValue;
  }
}
