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
              // العنوان
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // ✅ زر عرض الكل (يظهر فقط إذا تم تمرير onSeeAll)
              if (onSeeAll != null)
                InkWell(
                  onTap: onSeeAll, // تفعيل النقر
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: const [
                        Text(
                          "عرض الكل",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.pink, // لون لينيورا
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: Colors.pink,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // List
        SizedBox(
          height: 320,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            // ⚡ تأكد أن ProductCard عرضه مناسب (مثلاً 160) لترك مسافات
            itemExtent: 172,
            itemBuilder: (context, index) {
              // إضافة Padding بسيط حول الكارت لضمان وجود مسافة بين الكروت
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ProductCard(product: products[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
