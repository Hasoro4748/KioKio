import 'package:flutter/material.dart';

// 전체 ThemeData 설정
ThemeData mTheme() {
  return ThemeData(
    // 우리가 직접 지정 함
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: iconThemeColor,
      accentColor: iconThemeColor[900],
      cardColor: baseBackgroundColor[50],
      backgroundColor: baseBackgroundColor[500],
    ),
    cardColor: baseBackgroundColor[300],
    scaffoldBackgroundColor: baseBackgroundColor,
    textTheme: textTheme(),
    appBarTheme: appBarTheme(),
    bottomNavigationBarTheme: bottomNavigationBarTheme(),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PageColors.buttonBack,
        foregroundColor: PageColors.textBlue,
      ),
    ),
  );
}

AppBarTheme appBarTheme() {
  return AppBarTheme(
    centerTitle: false, //타이틀 중앙 여부
    backgroundColor: baseBackgroundColor, //타이틀 색상
    elevation: 0.0,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: iconThemeColor[700]), //아이콘 색상
    titleTextStyle: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 16, // 폰트 사이즈
        fontWeight: FontWeight.w900, // 굵기
        color: iconThemeColor[700] // 앱바 제목 텍스트 색상
        ),
  );
}

// 바텀네비게이션바 테마 설정
BottomNavigationBarThemeData bottomNavigationBarTheme() {
  return BottomNavigationBarThemeData(
    selectedItemColor: iconThemeColor[800], // 선택된 아이템 색상
    unselectedItemColor: iconThemeColor[300], // 선택되지 않은 아이템 색상
    showUnselectedLabels: true, // 선택 안된 라벨 표시 여부 설정
    backgroundColor: baseBackgroundColor,
    elevation: 0.0,
  );
}

//텍스트 테마
TextTheme textTheme() {
  return const TextTheme(
    // 가장 큰 제목 스타일
    displayLarge: TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 18.0,
        color: DefaultColors.black,
        fontWeight: FontWeight.w700),

    displayMedium: TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 16.0,
        color: DefaultColors.black,
        fontWeight: FontWeight.w400),

    bodyLarge: TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 16.0,
        color: DefaultColors.black,
        fontWeight: FontWeight.w100),

    bodyMedium: TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 14.0,
        color: DefaultColors.black,
        fontWeight: FontWeight.w400),

    bodySmall: TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 12.0,
        color: DefaultColors.black,
        fontWeight: FontWeight.w500),
  );
  // 두꺼운 제목 스타일
}

const int _baseColorValue = 0xFFF8FBFF;
const int _primaryColorValue = 0xFF6B85C2;

const MaterialColor baseBackgroundColor = MaterialColor(
  _baseColorValue,
  <int, Color>{
    50: Color(0xFFFCFDFF), // 거의 흰색, 아이콘이 선명하게 보임
    100: Color(0xFFF5F8FE), // 채도를 낮춘 연한 푸른빛 배경
    200: Color(0xFFEBF0FA), // 차분한 푸른빛이 감도는 뉴트럴 톤
    300: Color(0xFFDFE6F3), // 차가운 느낌을 줄이면서 부드럽게
    400: Color(0xFFD4DCEF), // 중간 정도 밝기의 배경색
    500: Color(0xFFBCC9DE), // 기본 배경색 (아이콘과 적절한 대비)
    600: Color(0xFFBAC5DD), // 좀 더 어두운 대체 배경
    700: Color(0xFFAAB6D0), // 뉴트럴하면서도 고급스러운 배경
    800: Color(0xFF98A5C1), // 너무 어둡지 않으면서도 차분한 느낌
    900: Color(0xFF8290AA), // 가장 어두운 배경 대체 색상
  },
);
const MaterialColor iconThemeColor = MaterialColor(
  _primaryColorValue,
  <int, Color>{
    50: Color(0xFFE8EBF5), // 아주 연한 톤
    100: Color(0xFFC5CEE7), // 연한 청보라
    200: Color(0xFF9EADD7), // 중간 밝기
    300: Color(0xFF788CC8), // 기본 색상보다 밝은 청보라
    400: Color(0xFF5973B9), // 약간 더 진한 청보라
    500: Color(_primaryColorValue), // 기본 색상 (#6B85C2)
    600: Color(0xFF5E77AE), // 어두운 청보라
    700: Color(0xFF4E6499), // 더 어두운 청보라
    800: Color(0xFF3E5185), // 진한 청보라
    900: Color(0xFF2C3965), // 가장 어두운 네이비 청보라
  },
);

class PageColors {
  static const Color theme = Color(0xFF98A5C1);
  static const Color themeSelect = Color(0xFF788CC8);
  static const Color themeUnSelect = Color(0xFFAAB6D0);
  static const Color cateSelect = Color(0xFF3E5185);
  static const Color cateUnSelect = Color(0xFF3E5185);
  static const Color themeBack = Color(0xFF5973B9);
  static const Color price = Color(0xFF3E5185);
  static const Color cateBack = Color(0xFFAAB6D0);
  static const Color textBlue = Color(0xFF3E5185);
  static const Color buttonBack = Color(0xFFE8EBF5);
}

class DefaultColors {
  static const Color black = Color(0xFF212121); // 아주 짙은 회색(글자색)
  static const Color white = Color(0xFFF1F1F1); // 아주 밝은 회색(글자색)
  static const Color green = Color(0xFF0ca678); // 눈이 편한 초록색 (글자색)
  static const Color yellow = Color(0xFFf7b233); // 약한 경고용 노란색 (글자색)
  static const Color red = Color(0xFFf03e3e); // 경고용 붉은색 (글자색)
  static const Color grey = Color(0xff979797); // 회색 (글자색)
  static const Color navy = Color(0xFF3E5185); // 남색 (버튼색)
  static const Color lightNavy = Color(0xFF788CC8); // 밝은 남색 (버튼색)
}

class CustomTextStyle {
  static const TextStyle bigLogo = TextStyle(fontSize: 50);
  static const TextStyle font = TextStyle(fontFamily: 'GmarketSans');
}
