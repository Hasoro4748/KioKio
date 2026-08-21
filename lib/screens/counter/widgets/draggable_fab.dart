import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DraggableFab extends StatefulWidget {
  final Widget child;
  final Offset initialPosition;

  const DraggableFab({
    super.key,
    required this.child,
    required this.initialPosition,
  });

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  late Offset position;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        feedback: Material(
          color: Colors.transparent,
          child: widget.child,
        ),
        childWhenDragging: Container(), // 드래그 중일 때 원래 자리는 비움
        onDragEnd: (details) {
          setState(() {
            // 화면 범위를 벗어나지 않도록 제한 (선택 사항)
            double x = details.offset.dx;
            double y = details.offset.dy;

            // 화면 끝에 너무 붙지 않게 보정
            final size = MediaQuery.of(context).size;
            if (x < 16) x = 16;
            if (x > size.width - 100) x = size.width - 100;
            if (y < 100) y = 100;
            if (y > size.height - 100) y = size.height - 100;

            position = Offset(x, y);
          });
        },
        child: widget.child,
      ),
    );
  }
}
