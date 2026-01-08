import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/categories/screens/category_products_screen.dart';
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

  bool _isGridView = true;
  String _activeFilter = 'all';

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
          _allCategories.where((category) {
            final matchesSearch = category.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
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
    // --- حسابات التجاوب ---
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

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
            // --- القسم العلوي ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
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
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [_buildFilterChip('الكل', 'all')],
                          ),
                        ),
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
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

            // --- المحتوى ---
            Expanded(
              child:
                  _isLoading
                      ? _buildLoadingSkeleton(isTablet)
                      : _filteredCategories.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                        onRefresh: _fetchCategories,
                        color: const Color(0xFFF105C6),
                        child:
                            _isGridView
                                ? _buildGridView(isTablet)
                                : _buildListView(isTablet),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
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
          color: isSelected ? const Color(0xFFF105C6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF105C6) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- Grid View (متجاوب) ---
  Widget _buildGridView(bool isTablet) {
    // في التابلت نعرض 5 أعمدة، وفي الموبايل 3
    final int crossAxisCount = isTablet ? 5 : 3;
    final double aspectRatio = isTablet ? 0.85 : 0.8;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        return _CategoryGridCard(category: _filteredCategories[index]);
      },
    );
  }

  // --- List View (متجاوب) ---
  Widget _buildListView(bool isTablet) {
    // في التابلت، عرض القائمة كسجل واحد طويل غير جميل.
    // لذا، نعرضها كقائمة عريضة (2 كولوم) لملء الشاشة.
    if (isTablet) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // عمودين للقائمة في التابلت
          childAspectRatio: 3.5, // بطاقة عريضة تشبه القائمة
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          return _CategoryListCard(category: _filteredCategories[index]);
        },
      );
    }

    // الموبايل العادي
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCategories.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _CategoryListCard(category: _filteredCategories[index]);
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

  Widget _buildLoadingSkeleton(bool isTablet) {
    final int crossAxisCount = isTablet ? 5 : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
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

// --- Cards (كما هي) ---
class _CategoryGridCard extends StatelessWidget {
  final CategoryModel category;
  const _CategoryGridCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CategoryProductsScreen(
                  slug: category.slug,
                  categoryName: category.name,
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
                        (context, url, error) => const Icon(Icons.error),
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

class _CategoryListCard extends StatelessWidget {
  final CategoryModel category;
  const _CategoryListCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CategoryProductsScreen(
                  slug: category.slug,
                  categoryName: category.name,
                ),
          ),
        );
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
