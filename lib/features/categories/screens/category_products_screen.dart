import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/categories/screens/categories_screen.dart';
import 'package:linyora_project/features/layout/main_layout_screen.dart';
import 'package:provider/provider.dart';

// --- Providers ---
import 'package:linyora_project/features/cart/providers/cart_provider.dart';
import 'package:linyora_project/features/auth/providers/auth_provider.dart';

// --- Screens ---
import 'package:linyora_project/features/cart/screens/cart_screen.dart';
import 'package:linyora_project/features/home/screens/notifications_screen.dart';
import 'package:linyora_project/features/home/widgets/search_screen.dart';

// --- Models & Widgets ---
import '../../../../models/category_model.dart';
import '../../../../models/product_model.dart';
import '../../shared/widgets/product_card.dart';
import '../services/category_service.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String slug;
  final String categoryName;

  const CategoryProductsScreen({
    Key? key,
    required this.slug,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = true;
  List<ProductModel> _products = [];
  List<CategoryModel> _subcategories = [];
  String _currentCategoryName = '';

  @override
  void initState() {
    super.initState();
    _currentCategoryName = widget.categoryName;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _categoryService.getCategoryProducts(widget.slug);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data != null) {
          _products = data.products;
          _subcategories = data.subcategories;
          if (data.categoryName.isNotEmpty) {
            _currentCategoryName = data.categoryName;
          }
        }
      });
    }
  }

  // ✅ بناء الـ AppBar المطابق للرئيسية
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
      // زر القائمة أو الرجوع حسب الصفحة
      leading:
          Navigator.canPop(context)
              ? const BackButton(
                color: Colors.black,
              ) // زر رجوع إذا كان هناك صفحة سابقة
              : IconButton(
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
          // الانتقال للصفحة الرئيسية وحذف كل الصفحات السابقة من المكدس
          Navigator.pushAndRemoveUntil(
            context,
            // ⚠️ تأكد من استيراد HomeScreen أو MainScreen (التي تحتوي على البار السفلي)
            MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
            (route) => false, // الشرط false يحذف كل شيء سابق
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
        // ... بقية الأزرار (إشعارات وسلة) كما هي ...
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
      // ... الجزء السفلي (bottom) كما هو ...
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
                    // يمكنك استخدام متغير لاسم القسم هنا إذا كنت في صفحة الأقسام
                    "عن ماذا تبحث اليوم؟",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  // ✅ عنوان القسم الحالي (Breadcrumb)
  Widget _buildCategoryHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            const Icon(Icons.category_outlined, color: Colors.pink, size: 20),
            const SizedBox(width: 8),
            Text(
              _currentCategoryName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              "${_products.length} منتج",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
      backgroundColor: Colors.grey[50],
      // ❌ تم حذف AppBar العادي
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF105C6)),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  int crossAxisCount = width > 900 ? 4 : (width > 600 ? 4 : 2);
                  double childAspectRatio = width > 600 ? 0.55 : 0.55;

                  return CustomScrollView(
                    slivers: [
                      // 1. الشريط العلوي الجديد
                      _buildSliverAppBar(),

                      // 2. عنوان القسم
                      _buildCategoryHeader(),

                      // 3. الأقسام الفرعية (Subcategories)
                      if (_subcategories.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            height: width > 600 ? 130 : 110,
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: _subcategories.length,
                              separatorBuilder:
                                  (c, i) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return _buildSubCategoryItem(
                                  _subcategories[index],
                                  isTablet: width > 600,
                                );
                              },
                            ),
                          ),
                        ),

                      // 4. شبكة المنتجات (Products Grid)
                      if (_products.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "لا توجد منتجات في هذا القسم حالياً",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return ProductCard(product: _products[index]);
                            }, childCount: _products.length),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildSubCategoryItem(CategoryModel sub, {bool isTablet = false}) {
    final double size = isTablet ? 75 : 60;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => CategoryProductsScreen(
                  slug: sub.slug,
                  categoryName: sub.name,
                ),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[200]!),
              image: DecorationImage(
                image: CachedNetworkImageProvider(sub.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: size + 10,
            child: Text(
              sub.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isTablet ? 13 : 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
