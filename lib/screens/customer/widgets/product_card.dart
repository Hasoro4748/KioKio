// lib/screens/customer/widgets/product_card.dart

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
    return RepaintBoundary(
      child: GestureDetector(
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
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 상품 이미지
                      KioskHelper.imageTypeBuilder(
                        product.thumbnail,
                        BoxFit.cover,
                      ),

                      // ★ 세트 상품일 때 [SET 세트] 배지 표시
                      if (product.isSet)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[800],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4)
                              ],
                            ),
                            child: const Text(
                              'SET 세트',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),

                      // 품절 시 어두운 오버레이
                      if (product.isSoldOut)
                        Container(
                          color: Colors.black.withOpacity(0.55),
                        ),

                      // 품절 이미지
                      if (product.isSoldOut)
                        Center(
                          child: Opacity(
                            opacity: 0.9,
                            child: Image.asset(
                              'assets/img/unit/soldOut.png',
                              width: 200,
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
                        decoration: product.isSoldOut
                            ? TextDecoration.lineThrough
                            : null,
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
                        decoration: product.isSoldOut
                            ? TextDecoration.lineThrough
                            : null,
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
