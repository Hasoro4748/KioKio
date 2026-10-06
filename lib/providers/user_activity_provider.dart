import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 앱 내 터치 조작 이벤트 발생 카운터 프로바이더
final userActivityProvider = StateProvider<int>((ref) => 0);
