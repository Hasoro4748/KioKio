import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk/utils/responsive.dart';

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

  static double calculateMaxExtent(
      BuildContext context, int desiredCount, bool isCartOpen, Responsive rs) {
    double screenWidth = MediaQuery.of(context).size.width;

    // 1. 사이드바 너비 제외 (기존 85 or 115)
    double sidebarWidth = rs.isMobile ? 85 : 115;
    double availableWidth = screenWidth - sidebarWidth;

    // 2. 장바구니가 열려 있다면 장바구니 너비 제외 (태블릿/데스크탑 30%)
    if (isCartOpen && !rs.isMobile && !rs.isTablet) {
      availableWidth -= (screenWidth * 0.3);
    }

    // 3. (가용 너비 / 원하는 열 개수)를 반환하여 그리드 생성 유도
    // 원하는 개수가 0이하인 경우 기본값 3 적용
    int count = desiredCount > 0 ? desiredCount : 3;
    return availableWidth / count;
  }
}
