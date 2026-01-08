import 'package:flutter/material.dart';
import 'package:linyora_project/features/products/widgets/product_filter_drawer.dart';
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

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> requestFilters = {};
      if (_sortBy.isNotEmpty) {
        requestFilters['sortBy'] = _sortBy;
      }
      requestFilters.addAll(_activeFilters);

      final List<ProductDetailsModel> rawProducts = await _productService
          .getProducts(limit: 50, filters: requestFilters);

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

  ProductModel _mapToProductModel(ProductDetailsModel detail) {
    final firstVariant =
        detail.variants.isNotEmpty ? detail.variants.first : null;

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
      compareAtPrice: firstVariant?.compareAtPrice,
      imageUrl:
          (firstVariant != null && firstVariant.images.isNotEmpty)
              ? firstVariant.images.first
              : '',
      rating: rating,
      reviewCount: detail.reviews.length,
      merchantName: detail.merchantName,
      isNew: false,
    );
  }

  List<ProductModel> _applyLocalFiltersAndSort(List<ProductModel> products) {
    var result = List<ProductModel>.from(products);

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
        result.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    return result;
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() => _sortBy = value);
      setState(() {
        _products = _applyLocalFiltersAndSort(_products);
      });
    }
  }

  void _onFiltersApplied(Map<String, dynamic> filters) {
    setState(() => _activeFilters = filters);
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9F9F9),
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.black),
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
          // Toolbar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Text(
                  "${_products.length} منتج",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                ),
                const SizedBox(width: 10),
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

          // Content
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
          // مساحة للتنقل السفلي
          const SizedBox(height: 70),
        ],
      ),
    );
  }

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

  // --- التعديل هنا: دالة بناء القائمة المتجاوبة ---
  Widget _buildProductsList() {
    // 1. حسابات التجاوب
    final double screenWidth = MediaQuery.of(context).size.width;

    // عدد الأعمدة: 2 للموبايل، 3 للتابلت، 4 للشاشات الكبيرة
    int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 4 : 2);

    // نسبة الأبعاد: تعديل بسيط للتابلت ليكون الكارت متناسقاً
    double childAspectRatio = screenWidth > 600 ? 0.55 : 0.53;

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount, // ديناميكي
          childAspectRatio: childAspectRatio, // ديناميكي
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: _products[index]);
        },
      );
    } else {
      // في وضع القائمة (List View)، في التابلت يمكننا عرض كارتين بجانب بعض بدلاً من واحد عريض جداً
      // أو الإبقاء على واحد عريض ولكن بتقييد العرض (Center & Constrain)
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Center(
            child: Container(
              // في التابلت، نحدد أقصى عرض للكارت لكي لا يمتط بشكل بشع
              constraints: const BoxConstraints(maxWidth: 600),
              height: 140,
              child: ProductCard(
                product: _products[index],
                width: double.infinity, // سيأخذ عرض الـ Container المقيد
                // هنا قد تحتاج لتعديل ProductCard ليدعم وضع الـ List (صورة يسار نص يمين)
                // إذا لم يكن يدعم، سيعرض الكارت العمودي بشكل مضغوط
              ),
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
