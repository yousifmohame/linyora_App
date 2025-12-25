import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../models/category_model.dart';
import '../../../../models/product_model.dart';
import '../../shared/widgets/product_card.dart'; // البطاقة الجديدة
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
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. الأقسام الفرعية (Subcategories Slider)
                    if (_subcategories.isNotEmpty) ...[
                      Container(
                        height: 110,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _subcategories.length,
                          separatorBuilder: (c, i) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final sub = _subcategories[index];
                            return _buildSubCategoryItem(sub);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // 2. شبكة المنتجات (Products Grid)
                    if (_products.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: Text("لا توجد منتجات في هذا القسم حالياً"),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ), // تقليل الهوامش الخارجية لأن البطاقة لها هوامش
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // عمودين
                                childAspectRatio:
                                    0.52, // نسبة الطول للعرض (زيادة الطول ليتسع للتفاصيل)
                                crossAxisSpacing: 0, // البطاقة تتكفل بالمسافات
                                mainAxisSpacing: 0,
                              ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            // نمرر المنتج للبطاقة بدون تحديد عرض ثابت
                            return ProductCard(product: _products[index]);
                          },
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  Widget _buildSubCategoryItem(CategoryModel sub) {
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
        children: [
          Container(
            width: 60,
            height: 60,
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
            width: 70,
            child: Text(
              sub.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
