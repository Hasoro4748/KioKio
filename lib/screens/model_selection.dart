import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/providers/database_provider.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/screens/counter/counter_page.dart';
import 'package:kiosk/screens/customer/product_list.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';

class ModelSelectionScreen extends ConsumerWidget {
  const ModelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final rs = Responsive(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              iconThemeColor[900]!, // 테마의 깊은 남색
              iconThemeColor[700]!, // 중간 톤의 남색
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: rs.h(0.02)),
                      // 로고 영역
                      Container(
                        padding: EdgeInsets.all(rs.padding(24)),
                        child: Image.asset(
                          'assets/icon/appIcon2.png',
                          width: rs.w(0.15).clamp(100.0, 160.0),
                        ),
                      ),
                      SizedBox(height: rs.h(0.02)),
                      Text(
                        'KIOKIO System',
                        style: TextStyle(
                          fontSize: rs.font(38),
                          fontWeight: FontWeight.w900,
                          color: iconThemeColor[50], // 밝은 대비색
                          letterSpacing: 2.0,
                          fontFamily: 'GmarketSans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '키오스크 & POS 통합 관리 솔루션',
                        style: TextStyle(
                          fontSize: rs.font(16),
                          color: iconThemeColor[100]!.withOpacity(0.7),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(height: rs.h(0.08)),

                      // 모드 선택 카드 레이아웃
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: rs.padding(20)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildModeCard(
                              context,
                              rs: rs,
                              title: 'POS 모드',
                              subtitle: '주문 수락 및 상품 관리',
                              icon: Icons.storefront_rounded,
                              color: iconThemeColor[300]!, // 테마 내 중간 밝기 파랑
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CounterMainScreen()),
                              ),
                            ),
                            SizedBox(width: rs.w(0.04)),
                            _buildModeCard(
                              context,
                              rs: rs,
                              title: '키오스크 모드',
                              subtitle: '고객용 무인 결제 시스템',
                              icon: Icons.qr_code_scanner_rounded,
                              color: iconThemeColor[300]!,
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CustomerHomeScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: rs.h(0.03)),

                      _buildAdminPanel(context, ref, db, rs),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "© 2026 Developer Hasoro. All rights reserved.",
                    style: TextStyle(
                      color: iconThemeColor[400]!.withOpacity(0.3),
                      fontSize: rs.font(12),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required Responsive rs,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cardWidth = rs.w(0.28).clamp(180.0, 260.0);
    final cardHeight = cardWidth * 1.15;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(rs.radius(32)),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: EdgeInsets.all(rs.padding(24)),
        decoration: BoxDecoration(
          color: iconThemeColor[800]!.withOpacity(0.4), // 카드 배경색
          borderRadius: BorderRadius.circular(rs.radius(32)),
          border: Border.all(
              color: iconThemeColor[600]!.withOpacity(0.2), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(rs.padding(18)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: rs.font(48), color: iconThemeColor[50]), // 아이콘도 통일감 있게
            ),
            SizedBox(height: rs.h(0.025)),
            Text(
              title,
              style: TextStyle(
                fontSize: rs.font(22),
                fontWeight: FontWeight.w900,
                color: iconThemeColor[50],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: rs.font(12),
                color: iconThemeColor[200]!.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPanel(
      BuildContext context, WidgetRef ref, dynamic db, Responsive rs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: iconThemeColor[900]!.withOpacity(0.5), // 더 어두운 패널
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.admin_panel_settings_rounded,
              color: iconThemeColor[300], size: 20),
          const SizedBox(width: 12),
          _buildSmallDebugButton(
            rs: rs,
            label: '초기화',
            icon: Icons.delete_sweep_rounded,
            color: DefaultColors.red, // 경고색 유지
            onTap: () async {
              await db.resetProducts();
              ref.invalidate(productProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('데이터베이스가 초기화되었습니다.')),
                );
              }
            },
          ),
          const SizedBox(width: 10),
          _buildSmallDebugButton(
            rs: rs,
            label: '데이터 복구',
            icon: Icons.restore_rounded,
            color: DefaultColors.green, // 성공색 유지
            onTap: () async {
              await db.resetProductsWithData();
              ref.invalidate(productProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('기본 상품 데이터가 복구되었습니다.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDebugButton({
    required Responsive rs,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: rs.font(16), color: color),
      label: Text(
        label,
        style: TextStyle(
            color: color, fontSize: rs.font(13), fontWeight: FontWeight.bold),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
            horizontal: rs.padding(16), vertical: rs.padding(8)),
        backgroundColor: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
