import 'package:flutter/material.dart';
import 'package:kiosk/models/product_image_model.dart';
import 'package:kiosk/utils/responsive.dart';

class ProductImagesSlider extends StatefulWidget {
  final List<ProductImageModel> images;

  const ProductImagesSlider({
    super.key,
    required this.images,
  });

  @override
  State<ProductImagesSlider> createState() => _ProductImagesSliderState();
}

class _ProductImagesSliderState extends State<ProductImagesSlider> {
  final PageController _controller = PageController();

  int currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);

    return Stack(
      children: [
        /// 이미지 슬라이드
        PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(
                rs.radius(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  rs.padding(12),
                ),
                child: Image.asset(
                  widget.images[index].imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),

        /// 이전 버튼
        if (currentIndex > 0)
          Positioned(
            left: rs.padding(8),
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                iconSize: rs.isMobile ? 34 : 42,
                splashRadius: rs.isMobile ? 24 : 30,
                icon: Icon(
                  Icons.arrow_circle_left_outlined,
                  color: Colors.black.withOpacity(0.8),
                ),
                onPressed: () {
                  _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),
          ),

        /// 다음 버튼
        if (currentIndex < widget.images.length - 1)
          Positioned(
            right: rs.padding(8),
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                iconSize: rs.isMobile ? 34 : 42,
                splashRadius: rs.isMobile ? 24 : 30,
                icon: Icon(
                  Icons.arrow_circle_right_outlined,
                  color: Colors.black.withOpacity(0.8),
                ),
                onPressed: () {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),
          ),

        /// 하단 인디케이터
        Positioned(
          bottom: rs.padding(12),
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (index) {
                final bool isSelected = currentIndex == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.symmetric(
                    horizontal: rs.padding(4),
                  ),
                  width: isSelected
                      ? rs.isMobile
                          ? 8
                          : 10
                      : rs.isMobile
                          ? 5
                          : 6,
                  height: isSelected
                      ? rs.isMobile
                          ? 8
                          : 10
                      : rs.isMobile
                          ? 5
                          : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
