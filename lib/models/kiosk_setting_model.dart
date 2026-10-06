class KioskSettingsModel {
  final int gridCount;
  final String logoPath;
  final String welcomeMessage;
  final int waitTime; // 대기 시간 (초)
  final bool useIdleScreen; // 대기화면 사용 여부
  final String idleMode;

  KioskSettingsModel({
    required this.gridCount,
    required this.logoPath,
    required this.welcomeMessage,
    required this.waitTime,
    required this.useIdleScreen,
    this.idleMode = 'use_idle',
  });

  Map<String, dynamic> toJson() => {
        'gridCount': gridCount,
        'logoPath': logoPath,
        'welcomeMessage': welcomeMessage,
        'waitTime': waitTime,
        'useIdleScreen': useIdleScreen,
        'idleMode': idleMode,
      };

  factory KioskSettingsModel.fromJson(Map<String, dynamic> json) {
    final bool legacyUseIdle = json['useIdleScreen'] ?? true;
    final String mode =
        json['idleMode'] ?? (legacyUseIdle ? 'use_idle' : 'off');

    return KioskSettingsModel(
      gridCount: json['gridCount'] ?? 3,
      logoPath: json['logoPath'] ?? '',
      welcomeMessage: json['welcomeMessage'] ?? '터치하여 주문을 시작하세요',
      waitTime: json['waitTime'] ?? 30,
      useIdleScreen: mode == 'use_idle',
      idleMode: mode,
    );
  }
}
