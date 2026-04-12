import 'package:flutter/services.dart';

class KioskHelper {
  static void initKioskMode() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  static Future<void> enterKioskMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  static void exitKioskMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
