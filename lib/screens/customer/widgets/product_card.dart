import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiosk/models/product.dart';
import 'package:kiosk/utils/text_util.dart';

class ProductCard extends StatelessWidget {
  final Product product;
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
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      image: DecorationImage(
                        image: AssetImage(product.images[0]),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  if (!product.canOrder)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.75,
                        child: Image.asset('assets/img/unit/soldOut.png'),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    product.name,
                    style: product.canOrder
                        ? const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)
                        : const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${TextUtil.money(product.basePrice)}원',
                    style: product.canOrder
                        ? const TextStyle(fontSize: 16, color: Colors.orange)
                        : const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough),
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
