import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linyora_project/features/cart/providers/cart_provider.dart'; // 1. استيراد البروفايدر
import 'package:linyora_project/features/wishlist/providers/wishlist_provider.dart';
import '../../../core/widgets/optimized_image.dart';
import '../../../models/product_model.dart';
import '../../products/screens/product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double width;

  const ProductCard({super.key, required this.product, this.width = 160});

  @override
  Widget build(BuildContext context) {
    // حساب نسبة الخصم
    int discountPercent = 0;
    if (product.compareAtPrice != null &&
        product.compareAtPrice! > product.price) {
      discountPercent =
          ((product.compareAtPrice! - product.price) /
                  product.compareAtPrice! *
                  100)
              .round();
    }

    return GestureDetector(
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
                        height: 1.1,
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
                            if (product.compareAtPrice != null &&
                                product.compareAtPrice! > product.price)
                              Text(
                                "${product.compareAtPrice!.toInt()} ﷼",
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

                        // زر إضافة للسلة (الذكي)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            // ✅ استدعاء دالة المعالجة الذكية
                            onTap: () => _handleAddToCartLogic(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF105C6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart_rounded,
                                color: Color(0xFFF105C6),
                                size: 20,
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

  // =========================================================
  // 🔥🔥🔥 المنطق الذكي للإضافة للسلة 🔥🔥🔥
  // =========================================================

  void _handleAddToCartLogic(BuildContext context) {
    // 1. التحقق هل المنتج له خيارات (Variants)؟
    bool hasVariants = product.variants != null && product.variants!.isNotEmpty;

    if (hasVariants) {
      // ✅ الحالة أ: يوجد خيارات -> نفتح نافذة سفلية للاختيار
      _showVariantSelectionSheet(context);
    } else {
      // ✅ الحالة ب: منتج بسيط -> إضافة مباشرة
      _addToCartDirectly(context, null);
    }
  }

  // إضافة مباشرة للسلة
  void _addToCartDirectly(BuildContext context, ProductVariant? variant) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // استدعاء دالة الإضافة (تأكد أن الدالة تقبل 3 مدخلات كما صححناها سابقاً)
    cartProvider.addToCart(
      product,
      1, // الكمية
      variant, // الخيار (قد يكون null للمنتج البسيط)
    );

    // إغلاق النافذة إذا كانت مفتوحة (في حالة الـ BottomSheet)
    if (variant != null) Navigator.pop(context);

    // إظهار رسالة النجاح
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text("تمت الإضافة للسلة بنجاح"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // نافذة اختيار المقاس/اللون السريعة
  void _showVariantSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // نستخدم StatefulBuilder لتحديث حالة الاختيار داخل الـ Sheet فقط
        ProductVariant? selectedVariant;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رأس النافذة
                  Row(
                    children: [
                      OptimizedImage(
                        imageUrl: product.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              selectedVariant != null
                                  ? "${selectedVariant!.price.toInt()} ﷼"
                                  : "${product.price.toInt()} ﷼",
                              style: const TextStyle(
                                color: Color(0xFFF105C6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text(
                    "اختر الخيار المناسب:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // قائمة الخيارات (Chips)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        product.variants!.map((variant) {
                          bool isSelected = selectedVariant == variant;
                          return ChoiceChip(
                            label: Text(
                              variant
                                  .name, // تأكد أن لديك حقل name أو value في المودل
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFFF105C6),
                            backgroundColor: Colors.grey[100],
                            onSelected: (val) {
                              setSheetState(() {
                                selectedVariant = val ? variant : null;
                              });
                            },
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // زر التأكيد
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          selectedVariant == null
                              ? null // تعطيل الزر إذا لم يتم الاختيار
                              : () =>
                                  _addToCartDirectly(context, selectedVariant),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF105C6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "إضافة للسلة",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProductDetailsScreen(productId: product.id.toString()),
      ),
    );
  }

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
