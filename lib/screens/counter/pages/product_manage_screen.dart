import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/screens/counter/widgets/product_add_dialog.dart';
import 'package:kiosk/screens/counter/widgets/product_info_detail_dialog.dart';
import 'package:kiosk/screens/counter/widgets/status_color.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/kiosk_helper.dart';
import 'package:kiosk/utils/text_util.dart';

class ProductManageScreen extends ConsumerStatefulWidget {
  const ProductManageScreen({super.key});

  @override
  ConsumerState<ProductManageScreen> createState() =>
      _ProductManageScreenState();
}

class _ProductManageScreenState extends ConsumerState<ProductManageScreen> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('상품관리'),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => const ProductAddDialog());
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('상품을 불러오지 못했습니다.\n$error'),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text('등록된 상품이 없습니다.'),
            );
          }
          return GridView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductGridItem(products[index]);
            },
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              //그리드 갯수, 추후 환경 설정 값으로 변경
              crossAxisCount: 5,
              //그리드 비율
              childAspectRatio: 1,
              //세로 비율
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGridItem(ProductModel product) {
    return GestureDetector(
      onTap: () {
        // 클릭 시 상세 정보 다이얼로그 호출
        showDialog(
          context: context,
          builder: (context) => ProductInfoDetailDialog(product: product),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 이미지 영역
            Expanded(
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: KioskHelper.imageTypeBuilder(
                      product.images.firstOrNull?.imagePath ?? '',
                      BoxFit.cover,
                    ),
                  ),
                  // 품절 시 어두운 오버레이
                  if (!product.isAvailable)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          '판매 중지',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 2. 정보 영역
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${TextUtil.money(product.basePrice)}원',
                    style: TextStyle(
                      color: PageColors.price,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 재고 상태 표시 (StatusColor 위젯 사용)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.stock <= 5
                              ? Colors.red[50]
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '재고: ${product.stock}개',
                          style: TextStyle(
                            color: product.stock <= 5
                                ? Colors.red
                                : Colors.blue[700],
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // 판매 상태 아이콘
                      Icon(
                        product.isAvailable
                            ? Icons.check_circle
                            : Icons.do_not_disturb_on,
                        color: product.isAvailable ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                    ],
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
