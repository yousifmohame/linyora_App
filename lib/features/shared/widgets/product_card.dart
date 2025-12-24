import 'package:flutter/material.dart';
import '../../../core/widgets/optimized_image.dart';
import '../../../models/product_model.dart';

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

    return Container(
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
          // --- القسم العلوي: الصورة + الشارات + التاجر والتقييم ---
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
                  width: width,
                  height: 220,
                ),
              ),
              // طبقة تظليل (Gradient) لضمان قراءة النصوص البيضاء
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4), // تظليل في الأعلى
                        Colors.transparent, // شفاف في الوسط
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // اسم التاجر + التقييم (في الأعلى داخل الصورة)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8, // ليمتد على العرض
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // اسم التاجر (مع أيقونة صغيرة)
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.merchantName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(blurRadius: 2, color: Colors.black45),
                            ], // ظل للنص
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // التقييم
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(
                          0.6,
                        ), // خلفية سوداء شفافة
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

              // شارة نسبة الخصم (في الأسفل اليسار داخل الصورة)
              if (discountPercent > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$discountPercent% خصم",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (product.isNew) // أو شارة "جديد"
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "جديد",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // زر المفضلة (قلب)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      // TODO: إضافة للمفضلة
                    },
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ),
            ],
          ),

          // --- القسم السفلي: الاسم والأسعار ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم المنتج
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

                  const Spacer(), // دفع الأسعار للأسفل
                  // الأسعار وزر الإضافة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // عمود الأسعار
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // السعر القديم (مشطوب)
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
                          // السعر الحالي
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

                      // زر إضافة للسلة صغير
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          color: Colors.black,
                          size: 24,
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
    );
  }
}
