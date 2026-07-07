import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/providers/repository_provider.dart';
import 'package:kiosk/utils/responsive.dart';

class ProductEditDialog extends ConsumerStatefulWidget {
  final ProductModel product;
  const ProductEditDialog({super.key, required this.product});

  @override
  ConsumerState<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends ConsumerState<ProductEditDialog> {
  late int _stock;
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _stock = widget.product.stock;
    _isAvailable = widget.product.isAvailable;
  }

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);

    return AlertDialog(
      title: Text('[${widget.product.name}] 관리'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 재고 수량 조절
          const Text('재고 수량 변경'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () => setState(() => _stock--),
                  icon: const Icon(Icons.remove_circle_outline)),
              Text('$_stock',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () => setState(() => _stock++),
                  icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
          const Divider(),
          // 판매 상태 스위치
          SwitchListTile(
            title: const Text('키오스크 판매 가능 여부'),
            value: _isAvailable,
            onChanged: (val) => setState(() => _isAvailable = val),
          ),
          const Divider(),
          // 삭제 버튼
          TextButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('상품 영구 삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소')),
        ElevatedButton(
          onPressed: () async {
            final updated = widget.product
                .copyWith(stock: _stock, isAvailable: _isAvailable);
            await ref.read(productRepositoryProvider).updateProduct(updated);
            ref.invalidate(productProvider);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('변경사항 저장'),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              await ref
                  .read(productRepositoryProvider)
                  .deleteProduct(widget.product.id!);
              ref.invalidate(productProvider);
              if (context.mounted) {
                Navigator.pop(ctx); // 확인창 닫기
                Navigator.pop(context); // 편집창 닫기
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
