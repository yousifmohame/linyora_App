import 'dart:async';
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "عروض مميزه 🔥",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,

        actions: [
          // عداد وقت عالمي في الهيدر (مثل علي اكسبريس)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: _GlobalCountDown()),
          ),
        ],
      ),
      body:
          _isLoading
              ? _buildGridSkeleton()
              : _products.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // بطاقتين في الصف
                  childAspectRatio: 0.58, // نسبة الطول للعرض (بطاقة طويلة)
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  return _TrendGridCard(
                    product: _products[index],
                    index: index,
                  );
                },
              ),
    );
  }

  Widget _buildGridSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder:
          (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Expanded(child: Container(color: Colors.grey[200])),
                Container(height: 80, color: Colors.white),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("لا توجد عروض حالياً"));
  }
}

class _TrendGridCard extends StatelessWidget {
  final PromotedProductModel product;
  final int index;

  const _TrendGridCard({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    // محاكاة لنسبة البيع (للعرض فقط)
    final double soldPercentage = (0.4 + (index % 5) * 0.1).clamp(0.0, 0.95);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ProductDetailsScreen(productId: product.id.toString()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الصورة مع التايمر والشارات
            Expanded(
              child: Stack(
                children: [
                  // الصورة
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => Container(color: Colors.grey[100]),
                    ),
                  ),

                  // شارة "خصم ساخن"
                  if (index < 3)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4747), // أحمر فاقع
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "HOT 🔥",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),

                  // عداد وقت صغير على الصورة (لأول 4 منتجات)
                  if (index < 4)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 24,
                        color: Colors.black.withOpacity(0.6),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              "ينتهي قريباً",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. التفاصيل
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // السعر
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "${product.price.toInt()}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const Text(
                        " ر.س",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (product.compareAtPrice != null)
                        Text(
                          "${product.compareAtPrice!.toInt()}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // شريط التقدم (Sold Bar) - ستايل علي اكسبريس
                  Stack(
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEB),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: soldPercentage,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9000), Color(0xFFFF4747)],
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          "تم بيع ${(soldPercentage * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // شارة الترويج أو اسم المنتج
                  if (product.promotionTierName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFF4747),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.promotionTierName,
                        style: const TextStyle(
                          color: Color(0xFFFF4747),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                      ),
                    )
                  else
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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

// ودجت العد التنازلي (الساعات : الدقائق : الثواني)
class _GlobalCountDown extends StatefulWidget {
  const _GlobalCountDown({Key? key}) : super(key: key);

  @override
  State<_GlobalCountDown> createState() => _GlobalCountDownState();
}

class _GlobalCountDownState extends State<_GlobalCountDown> {
  late Timer _timer;
  Duration _timeLeft = const Duration(
    hours: 4,
    minutes: 25,
    seconds: 13,
  ); // وقت افتراضي

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft.inSeconds > 0) {
            _timeLeft = _timeLeft - const Duration(seconds: 1);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_timeLeft.inHours);
    final minutes = twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(_timeLeft.inSeconds.remainder(60));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "ينتهي في ",
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
        _buildBox(hours),
        const Text(
          ":",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        _buildBox(minutes),
        const Text(
          ":",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        _buildBox(seconds),
      ],
    );
  }

  Widget _buildBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
