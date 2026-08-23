import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/utils/kiosk_helper.dart';
import 'package:kiosk/utils/text_util.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Column(
          children: [
            Expanded(
              // 1. ClipRRect를 사용하여 상단 영역의 모든 자식이 모서리를 넘지 못하게 자릅니다.
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand, // Stack이 부모 크기를 꽉 채우도록 설정
                  children: [
                    // 상품 이미지
                    KioskHelper.imageTypeBuilder(
                      product.images.firstOrNull?.imagePath ?? '',
                      BoxFit.cover,
                    ),

                    // 2. 품절 시 어두운 오버레이
                    if (product.isSoldOut)
                      Container(
                        color: Colors.black.withOpacity(0.55),
                      ),

                    // 3. 품절 이미지 (중앙 배치)
                    if (product.isSoldOut)
                      Center(
                        child: Opacity(
                          opacity: 0.9,
                          child: Image.asset(
                            'assets/img/unit/soldOut.png',
                            width: 200, // 이미지 크기는 적절히 조절하세요
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: product.isSoldOut ? Colors.grey : Colors.black87,
                      decoration:
                          product.isSoldOut ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${TextUtil.money(product.basePrice)}원',
                    style: TextStyle(
                      fontSize: 16,
                      color: product.isSoldOut ? Colors.grey : Colors.orange,
                      fontWeight: FontWeight.w600,
                      decoration:
                          product.isSoldOut ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
