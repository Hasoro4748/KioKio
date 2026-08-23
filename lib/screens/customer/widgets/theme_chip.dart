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
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            // 선택 시: 흰색에 가까운 아주 밝은 배경 사용
            // 비선택 시: 투명 배경 (테두리만 유지)
            color: selected ? Colors.white : Colors.black.withOpacity(0.05),

            border: Border.symmetric(
              horizontal: BorderSide(
                  color:
                      selected ? Colors.white : Colors.white.withOpacity(0.3)),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                // 선택 시: 테마의 가장 짙은 남색으로 텍스트 강조
                // 비선택 시: 흰색 텍스트 유지
                color: selected ? PageColors.cateSelect : Colors.white,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 15,
                fontFamily: 'GmarketSans',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
