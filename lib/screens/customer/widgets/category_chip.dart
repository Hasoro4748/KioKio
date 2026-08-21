import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiosk/theme/common_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double fSize;
  final bool enabled;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.fSize,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            // 선택 시 아주 연한 배경색을 주어 영역 구분
            color: selected
                ? PageColors.themeSelect.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: fSize,
                  fontFamily: 'GmarketSans',
                  // 선택 시 cateSelect(짙은 남색), 비선택 시 흐린 남색
                  color: selected
                      ? PageColors.cateSelect
                      : PageColors.textBlue.withOpacity(0.5),
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              // 하단 인디케이터 (둥근 모양으로 세련되게)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                width: selected ? 20 : 0,
                decoration: BoxDecoration(
                  color: PageColors.cateSelect,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
