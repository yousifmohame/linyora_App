import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/trends/services/trend_service.dart';
import '../../../models/promoted_product_model.dart';
import '../../products/screens/product_details_screen.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({Key? key}) : super(key: key);

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final TrendsService _service = TrendsService();

  List<PromotedProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final products = await _service.getPromotedProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: Colors.orange,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              "الأكثر رواجاً",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body:
          _isLoading
              ? _buildSkeletonLoading() // ✅ عرض الهيكل العظمي أثناء التحميل
              : _products.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                itemCount: _products.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _PromotedProductCard(
                    product: _products[index],
                    rank: index + 1,
                  );
                },
              ),
    );
  }

  // ودجت التحميل الاحترافي (Skeleton)
  Widget _buildSkeletonLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (ctx, index) => const SizedBox(height: 16),
      itemBuilder:
          (ctx, index) => Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[200], // لون رمادي ثابت أو متحرك
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 10,
                          color: Colors.grey[200],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 14,
                          color: Colors.grey[200],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 100,
                          height: 14,
                          color: Colors.grey[200],
                        ),
                        const Spacer(),
                        Container(
                          width: 60,
                          height: 16,
                          color: Colors.grey[200],
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

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_down, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "لا توجد منتجات ترند حالياً",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _PromotedProductCard extends StatelessWidget {
  final PromotedProductModel product;
  final int rank;

  const _PromotedProductCard({required this.product, required this.rank});

  @override
  Widget build(BuildContext context) {
    // ألوان الميداليات
    Color rankColor = Colors.grey.shade700;
    if (rank == 1) rankColor = const Color(0xFFFFD700);
    if (rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        // ✅ استخدام Material و InkWell للتأثير التفاعلي عند الضغط
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // ✅ الانتقال لصفحة التفاصيل مع تمرير الـ ID
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        ProductDetailsScreen(productId: product.id.toString()),
              ),
            );
          },
          child: Row(
            children: [
              // 1. الصورة (مع Hero Animation)
              SizedBox(
                width: 120,
                height: 140,
                child: Stack(
                  children: [
                    // ✅ Hero: يجعل الصورة تنتقل بسلاسة للصفحة التالية
                    Hero(
                      tag: 'product_image_${product.id}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(0),
                          right: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: product.image,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) =>
                                  Container(color: Colors.grey[50]),
                          errorWidget:
                              (context, url, error) => const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                        ),
                      ),
                    ),

                    // شارة الترتيب
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rankColor,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          "#$rank",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. التفاصيل
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // شارة الترويج (Top Tag)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (product.promotionTierName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: product.parsedBadgeColor.withOpacity(
                                  0.08,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: product.parsedBadgeColor.withOpacity(
                                    0.5,
                                  ),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                product.promotionTierName,
                                style: TextStyle(
                                  color: product.parsedBadgeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                          // زر القلب (المفضلة)
                          const Icon(
                            Icons.favorite_border,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Text(
                        product.brand.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),

                      const Spacer(),

                      // السعر وزر العربة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${product.price} ر.س",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFFF105C6),
                                ),
                              ),
                              if (product.compareAtPrice != null &&
                                  product.compareAtPrice! > product.price)
                                Text(
                                  "${product.compareAtPrice} ر.س",
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),

                          // زر "إضافة للسلة" صغير
                          // InkWell(
                          //   onTap: () {
                          //     // منطق الإضافة للسلة السريع
                          //     ScaffoldMessenger.of(context).showSnackBar(
                          //       const SnackBar(
                          //         content: Text("تمت الإضافة للسلة"),
                          //         duration: Duration(seconds: 1),
                          //       ),
                          //     );
                          //   },
                          //   child: Container(
                          //     padding: const EdgeInsets.all(8),
                          //     decoration: const BoxDecoration(
                          //       color: Colors.black,
                          //       shape: BoxShape.circle,
                          //     ),
                          //     child: const Icon(
                          //       Icons.add_shopping_cart,
                          //       color: Colors.white,
                          //       size: 16,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
