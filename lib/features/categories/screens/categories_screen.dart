import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/categories/screens/category_products_screen.dart';
import 'package:shimmer/shimmer.dart'; // يفضل إضافتها لعمل Loading Skeleton
import '../../../../models/category_model.dart';
import '../services/category_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _filteredCategories = [];
  bool _isLoading = true;

  // حالة العرض (شبكة أو قائمة)
  bool _isGridView = true;
  // حالة الفلتر (الكل، مميز، تريند)
  String _activeFilter = 'all'; // values: 'all', 'featured', 'trending'

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    final categories = await _categoryService.getAllCategories();
    if (mounted) {
      setState(() {
        _allCategories = categories;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredCategories =
          _allCategories.filter((category) {
            // 1. فلتر البحث
            final matchesSearch = category.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );

            // 2. فلتر التصنيف (Tags)
            bool matchesTag = true;
            if (_activeFilter == 'featured') {
              matchesTag = category.isFeatured;
            } else if (_activeFilter == 'trending') {
              matchesTag = category.isTrending;
            }

            return matchesSearch && matchesTag;
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "الأقسام",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 75),
        child: Column(
          children: [
            // --- القسم العلوي (بحث + فلاتر) ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // شريط البحث
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: "ابحث عن قسم...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // أدوات التحكم (فلاتر + تبديل العرض)
                  Row(
                    children: [
                      // أزرار الفلترة
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [_buildFilterChip('الكل', 'all')],
                          ),
                        ),
                      ),

                      // فاصل
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),

                      // زر تبديل العرض (Grid/List)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.grid_view,
                                color:
                                    _isGridView
                                        ? const Color(0xFFF105C6)
                                        : Colors.grey,
                              ),
                              onPressed:
                                  () => setState(() => _isGridView = true),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.view_list,
                                color:
                                    !_isGridView
                                        ? const Color(0xFFF105C6)
                                        : Colors.grey,
                              ),
                              onPressed:
                                  () => setState(() => _isGridView = false),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- محتوى القائمة ---
            Expanded(
              child:
                  _isLoading
                      ? _buildLoadingSkeleton()
                      : _filteredCategories.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                        onRefresh: _fetchCategories,
                        color: const Color(0xFFF105C6),
                        child:
                            _isGridView ? _buildGridView() : _buildListView(),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets مساعدة ---

  Widget _buildFilterChip(
    String label,
    String value, {
    IconData? icon,
    Color? color,
  }) {
    final bool isSelected = _activeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = value;
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? const Color(0xFFF105C6)) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? (color ?? const Color(0xFFF105C6))
                    : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Grid View Implementation
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 أعمدة مثل الموقع في الموبايل
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        return _CategoryGridCard(category: category);
      },
    );
  }

  // 2. List View Implementation
  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCategories.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        return _CategoryListCard(category: category);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text(
            "لا توجد أقسام مطابقة",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        // يمكنك استخدام مكتبة Shimmer هنا لنتيجة أفضل
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 60, height: 60, color: Colors.grey[200]),
              const SizedBox(height: 10),
              Container(width: 40, height: 10, color: Colors.grey[200]),
            ],
          ),
        );
      },
    );
  }
}

// --- بطاقة الشبكة (Grid Card) ---
class _CategoryGridCard extends StatelessWidget {
  final CategoryModel category;
  const _CategoryGridCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // ✅ التعديل هنا: الانتقال لشاشة المنتجات
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CategoryProductsScreen(
                  slug: category.slug, // نمرر الـ slug للباك إند
                  categoryName: category.name, // نمرر الاسم للعرض في العنوان
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: category.imageUrl ?? '',
                    fit: BoxFit.cover,
                    width: 70,
                    height: 70,
                    placeholder:
                        (context, url) => Container(color: Colors.grey[100]),
                    errorWidget:
                        (context, url, error) => Image.asset(
                          'assets/images/placeholder.png',
                        ), // صورة احتياطية
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- بطاقة القائمة (List Card) ---
class _CategoryListCard extends StatelessWidget {
  final CategoryModel category;
  const _CategoryListCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // الانتقال لصفحة المنتجات
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: category.imageUrl ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorWidget:
                    (context, url, error) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[100],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (category.children.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            '+${category.children.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.productCount} منتج',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// دالة مساعدة للفلترة في القوائم (Extension Method)
extension ListFilter<E> on List<E> {
  List<E> filter(bool Function(E element) test) {
    List<E> result = [];
    for (var element in this) {
      if (test(element)) result.add(element);
    }
    return result;
  }
}
