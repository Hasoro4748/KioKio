class KioskSettingsModel {
  final int gridCount;
  final String logoPath;
  final String welcomeMessage;
  final int waitTime; // 대기 시간 (초)
  final bool useIdleScreen; // 대기화면 사용 여부

  KioskSettingsModel({
    required this.gridCount,
    required this.logoPath,
    required this.welcomeMessage,
    required this.waitTime,
    required this.useIdleScreen,
  });

  Map<String, dynamic> toJson() => {
        'gridCount': gridCount,
        'logoPath': logoPath,
        'welcomeMessage': welcomeMessage,
        'waitTime': waitTime,
        'useIdleScreen': useIdleScreen,
      };

  factory KioskSettingsModel.fromJson(Map<String, dynamic> json) =>
      KioskSettingsModel(
        gridCount: json['gridCount'] ?? 3,
        logoPath: json['logoPath'] ?? '',
        welcomeMessage: json['welcomeMessage'] ?? '터치하여 주문을 시작하세요',
        waitTime: json['waitTime'] ?? 30, // 기본 30초
        useIdleScreen: json['useIdleScreen'] ?? true, // 기본 사용
      );
}
