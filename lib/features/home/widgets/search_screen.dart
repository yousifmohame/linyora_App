import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

// استيراد الموديلات والخدمات والصفحات
import 'package:linyora_project/models/product_model.dart';
import 'package:linyora_project/features/home/services/home_service.dart';
import '../../products/screens/product_details_screen.dart'; // تأكد من المسار

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HomeService _homeService = HomeService();

  List<ProductModel> _searchResults = [];
  List<String> _recentSearches = []; // أصبحت فارغة ليتم ملؤها من الذاكرة
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory(); // تحميل السجل عند فتح الصفحة
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- دوال إدارة سجل البحث (Local Storage) ---
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('search_history') ?? [];

    // إزالة التكرار (نحذف القديم ونضيف الجديد في البداية)
    if (history.contains(query)) {
      history.remove(query);
    }
    history.insert(0, query);

    // الاحتفاظ بآخر 10 عمليات بحث فقط
    if (history.length > 10) {
      history = history.sublist(0, 10);
    }

    await prefs.setStringList('search_history', history);
    setState(() {
      _recentSearches = history;
    });
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    await prefs.setStringList('search_history', history);
    setState(() {
      _recentSearches = history;
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _recentSearches = [];
    });
  }
  // ---------------------------------------------

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 600), () {
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

    // حفظ البحث في السجل فقط إذا كان طويلاً بما يكفي (اختياري)
    if (query.length > 2) {
      _addToHistory(query);
    }

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
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
            textInputAction:
                TextInputAction.search, // تغيير زر الكيبورد لـ "بحث"
            onSubmitted: (val) => _performSearch(val), // البحث عند ضغط Enter
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
                          setState(() {
                            _searchResults = [];
                          });
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
        child: CircularProgressIndicator(color: Color(0xFFF105C6)),
      ); // لون البراند
    }

    // الحالة 1: البحث فارغ -> عرض عمليات البحث السابقة
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

    // الحالة 3: عرض النتائج
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

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Text(
          "ابدأ البحث عن منتجاتك المفضلة",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "عمليات البحث الأخيرة",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_recentSearches.isNotEmpty)
                GestureDetector(
                  onTap: _clearHistory,
                  child: const Text(
                    "مسح الكل",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final term = _recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(term),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () => _removeFromHistory(term), // حذف عنصر واحد
                ),
                onTap: () {
                  _searchController.text = term;
                  // تحريك المؤشر للنهاية
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: term.length),
                  );
                  _performSearch(term);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return InkWell(
      onTap: () {
        // الانتقال لصفحة التفاصيل وتمرير الـ ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ProductDetailsScreen(productId: product.id.toString()),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة
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
                  fit: BoxFit.contain,
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
            // التفاصيل
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildRatingStars(product.rating),
                      const SizedBox(width: 4),
                      Text(
                        "(${product.reviewCount})",
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "${product.price.toInt()}",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              ".${((product.price - product.price.toInt()) * 100).toInt()}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: " ﷼",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontFamily: 'Arial',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 36,
                    width: 140,
                    child: ElevatedButton(
                      onPressed: () {
                        // الانتقال للتفاصيل لإضافة للسلة (لأن المنتج يحتاج اختيار لون/مقاس)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ProductDetailsScreen(
                                  productId: product.id.toString(),
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF105C6), // لون البراند
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "عرض التفاصيل",
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

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index < rating && rating % 1 != 0) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }
}
