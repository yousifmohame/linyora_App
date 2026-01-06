import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linyora_project/features/wishlist/providers/wishlist_provider.dart';
import '../../../core/widgets/optimized_image.dart';
import '../../../models/product_model.dart';
// استيراد شاشة التفاصيل
import '../../products/screens/product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double width;

  const ProductCard({super.key, required this.product, this.width = 160});

  @override
  Widget build(BuildContext context) {
    // 1. حساب نسبة الخصم
    int discountPercent = 0;
    if (product.compare_at_price != null &&
        product.compare_at_price! > product.price) {
      discountPercent =
          ((product.compare_at_price! - product.price) /
                  product.compare_at_price! *
                  100)
              .round();
    }

    return GestureDetector(
      // عند الضغط على الكارت بالكامل، انتقل لصفحة التفاصيل
      onTap: () => _navigateToDetails(context),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- القسم العلوي: الصورة + الشارات ---
            Stack(
              children: [
                // الصورة
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: OptimizedImage(
                    imageUrl: product.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    height: 215,
                  ),
                ),
                // طبقة تظليل
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // اسم التاجر + التقييم
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // اسم التاجر
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.storefront,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.merchantName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 2,
                                      color: Colors.black45,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // التقييم
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "${product.rating}",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // الشارات (خصم / جديد)
                if (discountPercent > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildBadge(
                      "$discountPercent% خصم",
                      Colors.redAccent,
                    ),
                  )
                else if (product.isNew)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildBadge("جديد", Colors.green),
                  ),

                // زر المفضلة
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<WishlistProvider>(
                    builder: (context, wishlist, _) {
                      final isLiked = wishlist.isWishlisted(product.id);
                      return GestureDetector(
                        onTap: () {
                          wishlist.toggleWishlist(product);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // --- القسم السفلي ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // الأسعار
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.compare_at_price != null &&
                                product.compare_at_price! > product.price)
                              Text(
                                "${product.compare_at_price!.toInt()} ﷼",
                                style: const TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                            Text(
                              "${product.price.toInt()} ﷼",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),

                        // زر إضافة للسلة (تم التعديل هنا)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            // عند الضغط، نفتح صفحة التفاصيل ليختار المقاس/اللون
                            onTap: () => _navigateToDetails(context),
                            child: Container(
                              padding: const EdgeInsets.all(6), // مساحة للضغط
                              decoration: BoxDecoration(
                                color: Colors.grey[100], // خلفية خفيفة
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons
                                    .shopping_cart_outlined, // تغيير لأيقونة مفرغة أجمل
                                color: Colors.black87,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة للتنقل
  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProductDetailsScreen(productId: product.id.toString()),
      ),
    );
  }

  // دالة مساعدة للشارات
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
