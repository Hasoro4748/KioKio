import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;

  Responsive(this.context);

  MediaQueryData get _mediaQuery => MediaQuery.of(context);

  double get screenWidth => _mediaQuery.size.width;
  double get screenHeight => _mediaQuery.size.height;

  /// 화면 타입
  bool get isMobile => screenWidth < 500;

  bool get isTablet => screenWidth >= 500 && screenWidth < 900;

  bool get isDesktop => screenWidth >= 900;

  /// width %
  double w(double percent) {
    return screenWidth * percent;
  }

  /// height %
  double h(double percent) {
    return screenHeight * percent;
  }

  /// 반응형 폰트
  double font(double size) {
    final scale = screenWidth / 1440;

    return (size * scale).clamp(
      size * 0.8,
      size * 1.25,
    );
  }

  /// 패딩
  double padding(double size) {
    final scale = screenWidth / 1440;

    return (size * scale).clamp(
      size * 0.7,
      size * 1.3,
    );
  }

  /// radius
  double radius(double size) {
    final scale = screenWidth / 1440;

    return (size * scale).clamp(
      size * 0.8,
      size * 1.4,
    );
  }
}
