import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  static ImageProvider getImageProvider(String? path) {
    if (path == null || path.isEmpty) {
      return const AssetImage('assets/img/unit/no_image.png'); // 기본 이미지
    }
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    return FileImage(File(path));
  }

  static Widget imageTypeBuilder(String? path, BoxFit boxFit) {
    if (path == null || path.isEmpty) {
      return Image.asset(
        'assets/img/unit/no_image.png',
        fit: boxFit,
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: boxFit,
      );
    }
    return Image.file(
      File(path),
      fit: boxFit,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
    );
  }
}
