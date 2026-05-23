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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fSize,
                    color: selected
                        ? PageColors.cateSelect
                        : PageColors.cateUnSelect,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Positioned(
                bottom: -1,
                left: 0,
                right: 0,
                child: Container(
                  height: 5,
                  color:
                      selected ? iconThemeColor.shade800 : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
