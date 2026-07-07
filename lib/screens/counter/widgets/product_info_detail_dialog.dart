import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/providers/repository_provider.dart';
import 'package:kiosk/screens/counter/widgets/product_edit_dialog.dart';
import 'package:kiosk/screens/customer/widgets/product_image_slider.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';

class ProductInfoDetailDialog extends StatelessWidget {
  final ProductModel product;

  const ProductInfoDetailDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final bool isMobile = rs.isMobile || rs.isTablet;

    return Dialog(
      insetPadding: EdgeInsets.all(rs.padding(16)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rs.radius(20))),
      child: Container(
        width: isMobile ? rs.w(0.95) : rs.w(0.75),
        height: isMobile ? rs.h(0.92) : rs.h(0.72),
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 750),
        child: isMobile
            ? _buildMobileLayout(context, rs)
            : _buildDesktopLayout(context, rs),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Responsive rs) {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildImageSection(rs)),
        Expanded(flex: 4, child: _buildInfoSection(context, rs)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, Responsive rs) {
    return Column(
      children: [
        Expanded(flex: 4, child: _buildImageSection(rs)),
        Expanded(flex: 6, child: _buildInfoSection(context, rs)),
      ],
    );
  }

  Widget _buildImageSection(Responsive rs) {
    return Padding(
      padding: EdgeInsets.all(rs.padding(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(rs.radius(16)),
          border: Border.all(width: 1, color: DefaultColors.grey),
        ),
        child: ProductImagesSlider(images: product.images),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Responsive rs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: rs.padding(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: TextStyle(
                        fontSize: rs.font(24), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${TextUtil.money(product.basePrice)}원',
                    style: TextStyle(
                        fontSize: rs.font(18),
                        color: PageColors.price,
                        fontWeight: FontWeight.w600)),
                const Divider(height: 40),
                Text('상품 설명',
                    style: TextStyle(
                        fontSize: rs.font(16), fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(product.description ?? '설명이 없습니다.',
                    style: TextStyle(
                        fontSize: rs.font(14), color: Colors.black87)),
                const SizedBox(height: 20),
                _buildStatusChips(rs),
                const SizedBox(height: 40),
                _buildEditButton(context, rs),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips(Responsive rs) {
    return Row(
      children: [
        Chip(label: Text('재고: ${product.stock}개')),
        const SizedBox(width: 8),
        Chip(
          label: Text(product.isAvailable ? '판매중' : '판매중지'),
          backgroundColor:
              product.isAvailable ? Colors.green[50] : Colors.red[50],
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context, Responsive rs) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context); // 조회창 닫기
          showDialog(
            context: context,
            builder: (context) => ProductEditDialog(product: product),
          );
        },
        icon: const Icon(Icons.edit_note),
        label: const Text('상품 정보 수정 / 관리'),
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15)),
      ),
    );
  }
}
