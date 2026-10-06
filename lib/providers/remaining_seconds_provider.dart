import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 키오스크 자동 초기화 남은 시간(초) 전역 프로바이더
final remainingSecondsProvider = StateProvider<int>((ref) => 999);
