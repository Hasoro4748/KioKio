// lib/screens/customer/widgets/theme_chip.dart

import 'package:flutter/material.dart';
import 'package:kiosk/theme/common_theme.dart';

class ThemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const ThemeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.35,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              // 선택 시: 입체적인 흰색 탭 배경 + 부드러운 그림자
              // 비선택 시: 은은한 어두운 반투명 배경
              color: selected ? Colors.white : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? Colors.white : Colors.white.withOpacity(0.15),
                width: 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: PageColors.cateSelect.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(2, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // ★ 1. 선택 시 좌측에 빛나는 4px 세로 인디케이터 바
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: selected ? 4 : 0,
                  height: 18,
                  decoration: BoxDecoration(
                    color: PageColors.cateSelect,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: selected ? 6 : 0),

                // ★ 2. 테마 명칭 텍스트
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? PageColors.cateSelect : Colors.white,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                      fontSize: 15,
                      fontFamily: 'GmarketSans',
                    ),
                  ),
                ),

                // ★ 3. 선택되었을 때 우측 영역 지표 화살표 (▶)
                if (selected)
                  const Icon(
                    Icons.arrow_right_rounded,
                    color: PageColors.cateSelect,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
