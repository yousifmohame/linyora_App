import 'package:flutter/material.dart';
import 'package:linyora_project/features/layout/main_layout_screen.dart';
import 'package:provider/provider.dart';
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/features/cart/providers/cart_provider.dart';
import 'package:linyora_project/features/cart/screens/cart_screen.dart';
import 'package:linyora_project/features/categories/screens/categories_screen.dart';
import 'package:linyora_project/features/home/screens/notifications_screen.dart';
import 'package:linyora_project/features/home/widgets/search_screen.dart';
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
      merchantId: detail.merchantId,
    );
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() => _sortBy = value);
      _fetchProducts();
    }
  }

  void _onFiltersApplied(Map<String, dynamic> filters) {
    setState(() => _activeFilters = filters);
    _fetchProducts();
  }

  // ✅ 1. تم الحفاظ على SliverAppBar كما هو
  Widget _buildSliverAppBar() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isRealAdmin =
        authProvider.user != null && authProvider.user!.roleId == 1;

    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.grid_view_outlined, color: Colors.black),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => CategoriesScreen()),
            ),
      ),

      // ✅ التعديل هنا: جعل العنوان قابلاً للنقر
      title: GestureDetector(
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            // ⚠️ تأكد أن HomeScreen هو اسم الكلاس الصحيح لصفحتك الرئيسية
            MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
            (route) => false, // يحذف كل الصفحات السابقة
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "INOYRA",
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Playfair Display',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 2.0,
              ),
            ),
            const Text(
              "L",
              style: TextStyle(
                color: Colors.pink,
                fontFamily: 'Playfair Display',
                fontWeight: FontWeight.w900,
                fontSize: 30,
                letterSpacing: 2.0,
              ),
            ),
            if (isRealAdmin)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "ADMIN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.black,
                size: 28,
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const NotificationsScreen(),
                    ),
                  ),
            ),
          ],
        ),
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => const CartScreen()),
                      ),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    top: 3,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          "${cart.itemCount}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: Container(
          height: 70,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const SearchScreen()),
                ),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    "عن ماذا تبحث اليوم؟",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 2. تم الحفاظ على SliverToBoxAdapter كما هو
  Widget _buildFilterToolbar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 16, color: Colors.black87),
                    const SizedBox(width: 6),
                    const Text(
                      "فلتر",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_activeFilters.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.pink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "${_products.length} منتج",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => setState(() => _isGridView = !_isGridView),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  _isGridView
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  size: 22,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 8),
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
                    DropdownMenuItem(value: 'latest', child: Text("الأحدث")),
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
    );
  }

  // ✅ 3. تم تحويل القائمة لتكون SliverGrid/SliverList لتعمل داخل CustomScrollView
  // دون المساس ببطاقة المنتج
  Widget _buildProductsGridSliver() {
    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
    double childAspectRatio = screenWidth > 600 ? 0.75 : 0.55;

    if (_isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.all(12),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => ProductCard(product: _products[index]),
            childCount: _products.length,
          ),
        ),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              height: 150,
              margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
              // استخدام بطاقة المنتج كما هي
              child: ProductCard(
                product: _products[index],
                width: double.infinity,
              ),
            ),
          );
        }, childCount: _products.length),
      );
    }
  }

  // دوال الحالات (Error, Empty) يجب أن تكون Slivers أيضاً أو مغلفة بـ SliverFillRemaining
  Widget _buildSliverError() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? "حدث خطأ غير معروف",
              style: const TextStyle(color: Colors.grey),
            ),
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
      ),
    );
  }

  Widget _buildSliverEmpty() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.manage_search_rounded,
              size: 80,
              color: Colors.grey[200],
            ),
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
      ),
    );
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
      // ✅ 4. استبدال Column بـ CustomScrollView لحل مشكلة الخطأ
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildFilterToolbar(),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFF105C6)),
              ),
            )
          else if (_error != null)
            _buildSliverError()
          else if (_products.isEmpty)
            _buildSliverEmpty()
          else
            _buildProductsGridSliver(),

          const SliverToBoxAdapter(child: SizedBox(height: 70)),
        ],
      ),
    );
  }
}
