import 'package:flutter/material.dart';
import 'package:linyora_project/features/products/widgets/product_filter_drawer.dart'; // تأكد من إنشاء هذا الملف
import 'package:linyora_project/features/shared/widgets/product_card.dart';
import 'package:linyora_project/models/product_model.dart';
import 'package:linyora_project/models/product_details_model.dart';
import 'package:linyora_project/features/products/services/product_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // حالة البيانات
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;

  // حالة العرض والفلترة
  bool _isGridView = true;
  String _sortBy = 'latest';
  Map<String, dynamic> _activeFilters = {};

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  /// دالة لجلب المنتجات وتحويلها
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. تجهيز جميع الفلاتر لإرسالها
      final Map<String, dynamic> requestFilters = {};

      // إضافة الترتيب
      if (_sortBy.isNotEmpty) {
        requestFilters['sortBy'] =
            _sortBy; // تأكد أن الاسم يطابق الباك إند (غالباً sortBy أو sort)
      }

      // إضافة الفلاتر النشطة (السعر، الماركات، إلخ)
      requestFilters.addAll(_activeFilters);

      // 2. استدعاء السيرفر مع الفلاتر
      final List<ProductDetailsModel> rawProducts = await _productService
          .getProducts(
            limit: 50, // نطلب عدد أكبر عند الفلترة
            filters: requestFilters, // <-- التغيير الجوهري هنا
          );

      // 3. تحويل البيانات للعرض
      final List<ProductModel> mappedProducts =
          rawProducts.map((detail) {
            return _mapToProductModel(detail);
          }).toList();

      if (mounted) {
        setState(() {
          _products = mappedProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "حدث خطأ أثناء تحميل المنتجات";
          _isLoading = false;
        });
        debugPrint("Error fetching products screen: $e");
      }
    }
  }

  /// دالة التحويل من تفاصيل إلى موديل العرض
  ProductModel _mapToProductModel(ProductDetailsModel detail) {
    // استخراج البيانات من المتغير الأول كواجهة افتراضية
    final firstVariant =
        detail.variants.isNotEmpty ? detail.variants.first : null;

    // حساب التقييم
    double rating = 0.0;
    if (detail.reviews.isNotEmpty) {
      final total = detail.reviews.fold(0.0, (sum, item) => sum + item.rating);
      rating = total / detail.reviews.length;
    }

    return ProductModel(
      id: detail.id,
      name: detail.name,
      description: detail.description,
      price: firstVariant?.price ?? 0.0,
      compare_at_price: firstVariant?.compareAtPrice,
      imageUrl:
          (firstVariant != null && firstVariant.images.isNotEmpty)
              ? firstVariant.images.first
              : '',
      rating: rating,
      reviewCount: detail.reviews.length,
      merchantName: detail.merchantName,
      isNew: false, // يمكن ربطها بتاريخ الإنشاء
    );
  }

  /// دالة لتطبيق الفلاتر والترتيب محلياً (مؤقتاً حتى يتم دعمها من السيرفر)
  List<ProductModel> _applyLocalFiltersAndSort(List<ProductModel> products) {
    var result = List<ProductModel>.from(products);

    // 1. فلتر السعر
    if (_activeFilters['price_min'] != null &&
        _activeFilters['price_max'] != null) {
      result =
          result
              .where(
                (p) =>
                    p.price >= _activeFilters['price_min'] &&
                    p.price <= _activeFilters['price_max'],
              )
              .toList();
    }

    // 2. الترتيب
    switch (_sortBy) {
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'latest':
      default:
        // نفترض أنها مرتبة افتراضياً أو حسب الـ ID
        result.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    return result;
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() => _sortBy = value);
      // إعادة تطبيق الترتيب فقط دون طلب الشبكة لتوفير الموارد
      setState(() {
        _products = _applyLocalFiltersAndSort(_products);
      });
    }
  }

  void _onFiltersApplied(Map<String, dynamic> filters) {
    setState(() => _activeFilters = filters);
    _fetchProducts(); // إعادة طلب البيانات لأن الفلترة قد تحتاج بيانات جديدة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9F9F9),
      // القائمة الجانبية للفلاتر
      endDrawer: ProductFilterDrawer(
        currentFilters: _activeFilters,
        onApplyFilters: _onFiltersApplied,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "منتجاتنا",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // زر الفلتر
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.tune,
                  color: Colors.black,
                ), // أيقونة الفلتر
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              if (_activeFilters.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط الأدوات العلوي (عدد المنتجات + الترتيب + طريقة العرض)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                // عدد النتائج
                Text(
                  "${_products.length} منتج",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),

                // أيقونات العرض
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      _buildViewIcon(Icons.grid_view_rounded, true),
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.grey.shade300,
                      ),
                      _buildViewIcon(Icons.view_list_rounded, false),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // قائمة الترتيب
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.black54,
                      ),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: _onSortChanged,
                      items: const [
                        DropdownMenuItem(
                          value: 'latest',
                          child: Text("الأحدث"),
                        ),
                        DropdownMenuItem(
                          value: 'price_asc',
                          child: Text("السعر: الأقل"),
                        ),
                        DropdownMenuItem(
                          value: 'price_desc',
                          child: Text("السعر: الأعلى"),
                        ),
                        DropdownMenuItem(
                          value: 'rating',
                          child: Text("الأعلى تقييماً"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // المحتوى الرئيسي
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF105C6),
                      ),
                    )
                    : _error != null
                    ? _buildErrorWidget()
                    : _products.isEmpty
                    ? _buildEmptyState()
                    : _buildProductsList(),
          ),
          SizedBox(height: 70),
        ],
      ),
    );
  }

  // ودجت أيقونة تغيير العرض
  Widget _buildViewIcon(IconData icon, bool isGrid) {
    final isSelected = _isGridView == isGrid;
    return InkWell(
      onTap: () => setState(() => _isGridView = isGrid),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? const Color(0xFFF105C6) : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55, // نسبة العرض للطول (تم تعديلها لتناسب الكارت)
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: _products[index]);
        },
      );
    } else {
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          // عرض القائمة (يمكنك إنشاء ProductListCard مخصص هنا إذا أردت)
          // حالياً نستخدم نفس الكارت ولكن بعرض كامل
          return SizedBox(
            height: 140,
            child: Row(
              children: [
                // يمكن تخصيص تصميم عرض القائمة هنا ليكون مختلفاً عن الشبكة
                Expanded(
                  child: ProductCard(
                    product: _products[index],
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text(
            "لا توجد منتجات تطابق الفلتر",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() => _activeFilters.clear());
              _fetchProducts();
            },
            child: const Text(
              "مسح جميع الفلاتر",
              style: TextStyle(color: Color(0xFFF105C6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF105C6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("إعادة المحاولة"),
          ),
        ],
      ),
    );
  }
}
