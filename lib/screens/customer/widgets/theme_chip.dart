import 'package:flutter/material.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';

class ThemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  const ThemeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final double chipSize = rs.isMobile ? 65 : 85;

    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: rs.padding(6)),
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Stack(
            // 선택 인디케이터를 위한 Stack
            alignment: Alignment.center,
            children: [
              // 1. 선택 시 왼쪽 인디케이터 바
              if (selected)
                Positioned(
                  left: 0,
                  child: Container(
                    width: 4,
                    height: chipSize * 0.6,
                    decoration: BoxDecoration(
                      color: PageColors.cateSelect,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

              // 2. 메인 칩 바디
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: chipSize,
                height: chipSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(selected ? 20 : 30),
                  color: selected
                      ? PageColors.themeSelect.withOpacity(0.2) // 선택 시 연한 배경
                      : Colors.transparent,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 이미지 영역
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(rs.padding(10)),
                        child: Image.asset(
                          'assets/img/theme/$label.png',
                          fit: BoxFit.contain,
                          // 선택되지 않았을 때 약간 흐리게 처리 가능
                          color:
                              selected ? null : Colors.white.withOpacity(0.8),
                          colorBlendMode: selected ? null : BlendMode.modulate,
                        ),
                      ),
                    ),
                    // 라벨 텍스트 (선택 시에만 강조하거나 작게 표시)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w500,
                          color:
                              selected ? PageColors.cateSelect : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
