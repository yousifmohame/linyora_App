import 'dart:async';
import 'package:flutter/material.dart';
import 'package:linyora_project/models/product_model.dart';
import 'package:linyora_project/features/home/services/home_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HomeService _homeService = HomeService();

  List<ProductModel> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  // قائمة وهمية لعمليات البحث السابقة (للمظهر الاحترافي)
  final List<String> _recentSearches = [
    "فستان سهرة",
    "ساعة ذكية",
    "حذاء رياضي",
    "حقيبة يد",
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    final results = await _homeService.searchProducts(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, // لون أمازون الرسمي أو الأبيض
        elevation: 0,
        titleSpacing: 0, // إزالة المسافات الزائدة
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // حقل البحث بتصميم Input Box
        title: Container(
          height: 45,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: "ابحث في Linyora...",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }

    // الحالة 1: البحث فارغ -> عرض عمليات البحث السابقة (ستايل أمازون)
    if (_searchController.text.isEmpty) {
      return _buildRecentSearches();
    }

    // الحالة 2: لا توجد نتائج
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "لم نجد نتائج لـ '${_searchController.text}'",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // الحالة 3: عرض النتائج (ستايل القائمة التفصيلية)
    return ListView.separated(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      separatorBuilder:
          (context, index) =>
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (context, index) {
        return _buildProductCard(_searchResults[index]);
      },
    );
  }

  // ودجت لعرض عمليات البحث السابقة
  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "عمليات البحث الأخيرة",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(_recentSearches[index]),
                trailing: const Icon(
                  Icons.north_west,
                  size: 16,
                  color: Colors.grey,
                ),
                onTap: () {
                  _searchController.text = _recentSearches[index];
                  _onSearchChanged(_recentSearches[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ودجت بطاقة المنتج (تصميم أمازون)
  Widget _buildProductCard(ProductModel product) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to details
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 150, // ارتفاع ثابت للبطاقة
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الصورة (يسار)
            Container(
              width: 130,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.contain, // contain أفضل للمنتجات لتظهر كاملة
                  placeholder:
                      (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  errorWidget:
                      (_, __, ___) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 2. التفاصيل (يمين)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight:
                          FontWeight.w400, // أمازون تستخدم خطاً عادياً للعناوين
                    ),
                  ),

                  const SizedBox(height: 6),

                  // التقييمات
                  Row(
                    children: [
                      _buildRatingStars(product.rating), // دالة لرسم النجوم
                      const SizedBox(width: 4),
                      Text(
                        "(${product.reviewCount})",
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // السعر
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "${product.price.toInt()}",
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ), // الرقم الصحيح كبير
                        ),
                        TextSpan(
                          text:
                              ".${((product.price - product.price.toInt()) * 100).toInt()}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ), // الكسور صغيرة علوية
                        ),
                        TextSpan(
                          text: " ﷼",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontFamily: 'Arial',
                          ), // العملة صغيرة
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // زر الإضافة للسلة (الأصفر المميز)
                  SizedBox(
                    height: 36,
                    width: 140,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          155,
                          126,
                          203,
                        ),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "أضف إلى العربة",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لرسم النجوم
  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.orange, size: 16);
        } else if (index < rating && rating % 1 != 0) {
          return const Icon(Icons.star_half, color: Colors.orange, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.orange, size: 16);
        }
      }),
    );
  }
}
