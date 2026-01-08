import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _currentCategoryName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF105C6)),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  // --- حسابات التجاوب ---
                  final double width = constraints.maxWidth;

                  // عدد الأعمدة: 2 للموبايل، 3 للتابلت، 4 للشاشات الكبيرة
                  int crossAxisCount = width > 900 ? 4 : (width > 600 ? 4 : 2);

                  // نسبة الأبعاد: نعدلها قليلاً في التابلت لتكون البطاقة متناسقة
                  double childAspectRatio = width > 600 ? 0.55 : 0.52;

                  return CustomScrollView(
                    slivers: [
                      // 1. الأقسام الفرعية (Subcategories)
                      if (_subcategories.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            height:
                                width > 600
                                    ? 130
                                    : 110, // تكبير الارتفاع قليلاً في التابلت
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

                      // 2. شبكة المنتجات (Products Grid)
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
                                  crossAxisCount: crossAxisCount, // ديناميكي
                                  childAspectRatio:
                                      childAspectRatio, // ديناميكي
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

                      // مسافة سفلية
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildSubCategoryItem(CategoryModel sub, {bool isTablet = false}) {
    final double size = isTablet ? 75 : 60; // تكبير الأيقونة في التابلت

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
