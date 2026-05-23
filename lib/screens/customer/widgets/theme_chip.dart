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

    final double chipSize = rs.isMobile
        ? 60
        : rs.isTablet
            ? 72
            : 80;

    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: rs.padding(4),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            selected ? rs.radius(25) : rs.radius(60),
          ),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: chipSize,
            height: chipSize,
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: PageColors.themeUnSelect,
              ),
              borderRadius: BorderRadius.circular(
                selected ? 20 : 60,
              ),
              color:
                  selected ? PageColors.themeSelect : PageColors.themeUnSelect,
            ),
            child: Padding(
              padding: EdgeInsets.all(
                rs.padding(8),
              ),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    color: selected
                        ? PageColors.cateSelect
                        : PageColors.cateUnSelect,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
