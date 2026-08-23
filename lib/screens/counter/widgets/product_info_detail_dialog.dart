import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/screens/counter/widgets/product_edit_dialog.dart';
import 'package:kiosk/screens/customer/widgets/product_image_slider.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';

class ProductInfoDetailDialog extends ConsumerWidget {
  // ConsumerWidget으로 변경
  final ProductModel product;

  const ProductInfoDetailDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rs = Responsive(context);
    final bool isMobile = rs.isMobile || rs.isTablet;

    return Dialog(
      insetPadding: EdgeInsets.all(rs.padding(16)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rs.radius(24))),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: isMobile ? rs.w(0.95) : rs.w(0.8),
        height: isMobile ? rs.h(0.9) : rs.h(0.8),
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 850),
        child: isMobile
            ? _buildMobileLayout(context, rs, ref)
            : _buildDesktopLayout(context, rs, ref),
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, Responsive rs, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 5, child: _buildImageSection(rs)),
        const VerticalDivider(width: 1),
        Expanded(flex: 5, child: _buildInfoSection(context, rs, ref)),
      ],
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, Responsive rs, WidgetRef ref) {
    return Column(
      children: [
        Expanded(flex: 4, child: _buildImageSection(rs)),
        Expanded(flex: 6, child: _buildInfoSection(context, rs, ref)),
      ],
    );
  }

  // 1. 이미지 슬라이더 섹션
  Widget _buildImageSection(Responsive rs) {
    return Container(
      color: Colors.grey[50],
      child: Stack(
        children: [
          Center(child: ProductImagesSlider(images: product.images)),
          // 재고 부족 경고 배지
          if (product.stock <= 5 && product.isAvailable)
            Positioned(
              top: 20,
              left: 20,
              child: _buildWarningBadge('재고 부족', Colors.orange),
            ),
          if (!product.isAvailable)
            Positioned(
              top: 20,
              left: 20,
              child: _buildWarningBadge('판매 중지됨', Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildWarningBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // 2. 정보 및 상세 관리 섹션
  Widget _buildInfoSection(BuildContext context, Responsive rs, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('상품 상세 정보',
                  style: TextStyle(
                      fontSize: rs.font(18),
                      fontWeight: FontWeight.w900,
                      color: PageColors.textBlue)),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        const Divider(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이름과 가격
                Text(product.name,
                    style: TextStyle(
                        fontSize: rs.font(28),
                        fontWeight: FontWeight.bold,
                        color: DefaultColors.black)),
                const SizedBox(height: 8),
                Text('${TextUtil.money(product.basePrice)}원',
                    style: TextStyle(
                        fontSize: rs.font(22),
                        color: PageColors.price,
                        fontWeight: FontWeight.w800)),

                const SizedBox(height: 24),
                _buildSectionTitle('상품 상태 및 재고'),
                _buildStatusRow(rs),

                const SizedBox(height: 24),
                _buildSectionTitle('상품 설명'),
                Text(
                    product.description.isEmpty
                        ? '등록된 설명이 없습니다.'
                        : product.description,
                    style: TextStyle(
                        fontSize: rs.font(14),
                        color: Colors.black87,
                        height: 1.6)),

                const SizedBox(height: 24),
                _buildSectionTitle('분류 및 태그 정보'),
                _buildTagSection(
                    '테마', product.themes, Colors.blue[50]!, Colors.blue[700]!),
                const SizedBox(height: 12),
                _buildTagSection('판매자', product.sellers, Colors.green[50]!,
                    Colors.green[700]!),
                const SizedBox(height: 12),
                _buildTagSection('카테고리', product.categories, Colors.purple[50]!,
                    Colors.purple[700]!),

                const SizedBox(height: 32),
                _buildSectionTitle('시스템 기록'),
                _buildTimeInfo('등록일', product.createdAt),
                _buildTimeInfo('최종 수정일', product.updatedAt),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // 하단 버튼 영역
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('삭제', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                        context: context,
                        builder: (context) =>
                            ProductEditDialog(product: product));
                  },
                  icon: const Icon(Icons.edit_document),
                  label: const Text('상품 정보 수정하기'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: PageColors.cateSelect,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: PageColors.themeSelect),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(Responsive rs) {
    final bool lowStock = product.stock <= 5;
    return Row(
      children: [
        _buildInfoTile(Icons.inventory_2, '현재 재고', '${product.stock}개',
            lowStock ? Colors.red : Colors.blue),
        const SizedBox(width: 16),
        _buildInfoTile(
            product.isAvailable ? Icons.check_circle : Icons.do_not_disturb_on,
            '판매 상태',
            product.isAvailable ? '판매 중' : '판매 중지',
            product.isAvailable ? Colors.green : Colors.grey),
      ],
    );
  }

  Widget _buildInfoTile(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
              Text(value,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTagSection(
      String label, List<String> tags, Color bgColor, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 60,
            child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(label,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)))),
        Expanded(
          child: tags.isEmpty
              ? const Text('-', style: TextStyle(color: Colors.grey))
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(t,
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ))
                      .toList()),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(String label, DateTime time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(DateFormat('yyyy-MM-dd HH:mm').format(time),
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상품 삭제'),
        content:
            Text('[${product.name}] 상품을 정말 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              ref.read(productProvider.notifier).deleteProduct(product.id);
              Navigator.pop(context); // 컨펌창 닫기
              Navigator.pop(context); // 상세창 닫기
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('삭제하기'),
          ),
        ],
      ),
    );
  }
}
