// lib/screens/customer/widgets/category_chip.dart

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
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.3,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              // 선택 시: 짙은 남색 캡슐 칩 + 입체 그림자
              // 비선택 시: 흰색 칩 + 연한 남색 테두리
              color: selected ? PageColors.cateSelect : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? PageColors.cateSelect
                    : PageColors.cateSelect.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: PageColors.cateSelect.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ★ 1. 선택 시 하얀 체크 심볼 아이콘 노출
                if (selected) ...[
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                ],

                // ★ 2. 카테고리 명칭 텍스트
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fSize,
                    fontFamily: 'GmarketSans',
                    color: selected ? Colors.white : PageColors.cateSelect,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
