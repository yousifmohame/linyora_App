import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../../shared/widgets/product_card.dart';

class HorizontalProductList extends StatelessWidget {
  final String title;
  final List<ProductModel> products;
  final VoidCallback? onSeeAll;

  const HorizontalProductList({
    super.key,
    required this.title,
    required this.products,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: const Text("عرض الكل", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
            ],
          ),
        ),

        // List
        SizedBox(
          height: 320, // ارتفاع مناسب للكارت
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemExtent: 172, // ⚡ تحسين الأداء: تحديد عرض ثابت للعنصر (160 عرض + 12 هامش)
            itemBuilder: (context, index) {
              return ProductCard(product: products[index]);
            },
          ),
        ),
      ],
    );
  }
}