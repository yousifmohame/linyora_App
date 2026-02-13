import 'dart:async'; // 1. استيراد المكتبة الخاصة بالتوقيت
import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../../shared/widgets/product_card.dart';

class HorizontalProductList extends StatefulWidget {
  final String title;
  final List<ProductModel> products;
  final VoidCallback? onSeeAll;
  final bool autoScroll; // خيار لتفعيل/تعطيل التمرير التلقائي

  const HorizontalProductList({
    super.key,
    required this.title,
    required this.products,
    this.onSeeAll,
    this.autoScroll = true, // مفعل افتراضياً
  });

  @override
  State<HorizontalProductList> createState() => _HorizontalProductListState();
}

class _HorizontalProductListState extends State<HorizontalProductList> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  bool _isUserInteracting = false; // لتتبع لمس المستخدم

  @override
  void initState() {
    super.initState();
    // بدء التمرير التلقائي عند بناء الواجهة
    if (widget.autoScroll && widget.products.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoScroll();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // إيقاف المؤقت عند الخروج
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    // التحرك كل 3 ثواني
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isUserInteracting || !_scrollController.hasClients) return;

      // 172 هو نفس الـ itemExtent الذي حددته
      double currentOffset = _scrollController.offset;
      double maxScroll = _scrollController.position.maxScrollExtent;
      double step = 172.0;

      double targetOffset = currentOffset + step;

      // إذا وصلنا للنهاية، نعود للبداية
      if (targetOffset >= maxScroll + step) {
        // +step لإعطاء فرصة لرؤية آخر عنصر
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        // التحرك للعنصر التالي
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onSeeAll != null)
                InkWell(
                  onTap: widget.onSeeAll,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: const [
                        Text(
                          "عرض الكل",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.pink,
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
          // ✅ إضافة Listener لاكتشاف لمس المستخدم
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              if (scrollNotification is ScrollStartNotification) {
                // المستخدم بدأ اللمس -> أوقف التمرير التلقائي
                _isUserInteracting = true;
              } else if (scrollNotification is ScrollEndNotification) {
                // المستخدم توقف عن اللمس -> أعد التمرير بعد قليل
                Future.delayed(const Duration(seconds: 5), () {
                  if (mounted) {
                    _isUserInteracting = false;
                  }
                });
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController, // ✅ ربط المتحكم
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: widget.products.length,
              itemExtent: 172, // عرض العنصر الثابت
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ProductCard(product: widget.products[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
