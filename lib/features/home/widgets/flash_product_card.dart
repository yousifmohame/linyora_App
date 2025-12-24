import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../models/flash_sale_model.dart';

class FlashProductCard extends StatelessWidget {
  final FlashProduct product;

  const FlashProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    double soldPercentage = (product.sold / product.total);
    if (soldPercentage > 1.0) soldPercentage = 1.0;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. الصورة مع نسبة الخصم
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: product.image,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[100]),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "-${product.discountPercent}%",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // 2. التفاصيل
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الاسم
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),

                // السعر
                Row(
                  children: [
                    Text(
                      "${product.discountPrice.toInt()} ﷼",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${product.originalPrice.toInt()}",
                      style: const TextStyle(
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // شريط التقدم (الكمية المباعة)
                LinearPercentIndicator(
                  lineHeight: 14.0, // سمك الشريط
                  percent: soldPercentage,
                  center: Text(
                    product.sold >= product.total 
                      ? "نفدت الكمية" 
                      : "${(soldPercentage * 100).toInt()}% تم بيعه",
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  barRadius: const Radius.circular(10),
                  backgroundColor: Colors.grey[200],
                  progressColor: Colors.orange,
                  animation: true,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}