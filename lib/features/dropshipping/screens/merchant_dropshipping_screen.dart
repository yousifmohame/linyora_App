import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/features/subscriptions/screens/subscription_plans_screen.dart';
import '../models/supplier_product_model.dart';
import '../services/dropshipping_service.dart';

class MerchantDropshippingScreen extends StatefulWidget {
  const MerchantDropshippingScreen({Key? key}) : super(key: key);

  @override
  State<MerchantDropshippingScreen> createState() =>
      _MerchantDropshippingScreenState();
}

class _MerchantDropshippingScreenState
    extends State<MerchantDropshippingScreen> {
  final DropshippingService _service = DropshippingService();

  // State
  List<SupplierProduct> _allProducts = [];
  List<SupplierProduct> _filteredProducts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final Set<int> _importingIds = {}; // لتتبع المنتجات التي يتم استيرادها حالياً

  // Filters
  String _searchTerm = '';
  String _selectedCategory = 'all';
  List<String> _categories = ['all'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccessAndFetch();
    });
  }

  void _checkAccessAndFetch() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    // التحقق من الصلاحية (نفس منطق Gate)
    bool hasAccess = user?.subscription?.hasDropshippingAccess ?? false;

    if (hasAccess) {
      _fetchProducts();
    } else {
      setState(() => _isLoading = false); // إيقاف التحميل لعرض البوابة
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      if (_allProducts.isEmpty) _isLoading = true;
      _isRefreshing = true;
    });

    try {
      final products = await _service.getSupplierProducts();

      // استخراج التصنيفات الفريدة
      final categorySet = <String>{'all'};
      for (var p in products) {
        if (p.categories.isNotEmpty) {
          categorySet.addAll(p.categories.split(', '));
        }
      }

      if (mounted) {
        setState(() {
          _allProducts = products;
          _categories = categorySet.toList();
          _applyFilters(); // تطبيق الفلتر المبدئي
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل تحميل المنتجات')));
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts =
          _allProducts.filter((p) {
            final matchesSearch =
                p.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                p.brand.toLowerCase().contains(_searchTerm.toLowerCase());
            final matchesCategory =
                _selectedCategory == 'all' ||
                p.categories.contains(_selectedCategory);
            return matchesSearch && matchesCategory;
          }).toList();
    });
  }

  Future<void> _handleImport(int id, double price) async {
    setState(() => _importingIds.add(id));
    try {
      await _service.importProduct(id, price);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إضافة المنتج لمتجرك بنجاح!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // تحسين مظهر التنبيه
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '❌ فشل الاستيراد';
        Color snackBarColor = Colors.red;

        // تحويل الخطأ لنص للتحقق من محتواه
        final errorString = e.toString().toLowerCase();

        // 1. التحقق مما إذا كان الخطأ بسبب التكرار
        // (قم بتعديل الكلمات المفتاحية هنا بناءً على ما يرسله الباك إند لديك)
        if (errorString.contains('exist') ||
            errorString.contains('duplicate') ||
            errorString.contains('already')) {
          errorMessage = '⚠️ هذا المنتج موجود بالفعل في متجرك!';
          snackBarColor = Colors.orange; // لون تحذيري بدلاً من الأحمر
        }
        // تحقق إضافي إذا كانت الرسالة تأتي مباشرة بالعربية
        else if (errorString.contains('موجود مسبقا')) {
          errorMessage = '⚠️ هذا المنتج موجود بالفعل في متجرك!';
          snackBarColor = Colors.orange;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                // تغيير الأيقونة حسب نوع الخطأ
                Icon(
                  snackBarColor == Colors.orange
                      ? Icons.warning_amber
                      : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: snackBarColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final bool hasAccess = user?.subscription?.hasDropshippingAccess ?? false;

    // 1. عرض البوابة (Gate) إذا لم يكن لديه صلاحية
    if (!hasAccess && !_isLoading) {
      return _buildSubscriptionGate();
    }

    // 2. المحتوى الرئيسي
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // خلفية فاتحة جداً
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF1F2),
              Color(0xFFF3E8FF),
            ], // Rose-50 to Purple-50
          ),
        ),
        child: SafeArea(
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF43F5E)),
                  )
                  : CustomScrollView(
                    slivers: [
                      // Header & Stats & Filters
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildStatsCards(),
                              const SizedBox(height: 20),
                              _buildFilters(),
                            ],
                          ),
                        ),
                      ),

                      // Products Grid
                      _filteredProducts.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmptyState())
                          : SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2, // عمودين
                                    childAspectRatio:
                                        0.65, // نسبة الطول للعرض (لجعل الكارت طويلاً)
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildProductCard(_filteredProducts[index]),
                                childCount: _filteredProducts.length,
                              ),
                            ),
                          ),

                      // Bottom Padding
                      const SliverToBoxAdapter(child: SizedBox(height: 30)),
                    ],
                  ),
        ),
      ),
    );
  }

  // --- Components ---

  Widget _buildSubscriptionGate() {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1F2), Color(0xFFF3E8FF)],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Color(0xFFE11D48),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "محتوى حصري",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "هذه الميزة متاحة فقط للمشتركين في باقة الدروب شيبينج. قم بالترقية للوصول إلى آلاف المنتجات الجاهزة للبيع.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionPlansScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text("ترقية الباقة الآن"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF43F5E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          "سوق الدروب شيبينج",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.transparent, // Gradient Text Trick
            shadows: [Shadow(offset: Offset(0, -5), color: Colors.black)],
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFFF43F5E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "استكشف آلاف المنتجات وأضفها لمتجرك بنقرة زر واحدة",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    // حساب الإحصائيات
    int total = _allProducts.length;
    int featured = _allProducts.where((p) => p.isFeatured).length;
    int suppliers = _allProducts.map((p) => p.supplierName).toSet().length;

    return Row(
      children: [
        _buildStatItem(total, "إجمالي المنتجات", Colors.pink),
        const SizedBox(width: 8),
        _buildStatItem(featured, "منتجات مميزة", Colors.purple),
        const SizedBox(width: 8),
        _buildStatItem(suppliers, "الموردين", Colors.blue),
      ],
    );
  }

  Widget _buildStatItem(int count, String label, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.shade100),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Column(
          children: [
            Text(
              "$count",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Search
          TextField(
            onChanged: (val) {
              _searchTerm = val;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: "بحث عن منتج...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          // Row: Category & Refresh
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items:
                          _categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c == 'all' ? 'جميع التصنيفات' : c,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val!;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isRefreshing ? null : _fetchProducts,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon:
                    _isRefreshing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(SupplierProduct product) {
    final firstVariant =
        product.variants.isNotEmpty ? product.variants.first : null;
    final String imageUrl =
        (firstVariant != null && firstVariant.images.isNotEmpty)
            ? firstVariant.images.first
            : ''; // Placeholder logic handle later
    final double price = firstVariant?.costPrice ?? 0.0;
    final bool isImporting = _importingIds.contains(product.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder:
                        (c, u) => Container(color: Colors.grey.shade100),
                    errorWidget:
                        (c, u, e) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                  )
                else
                  Container(
                    color: Colors.grey.shade100,
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.grey,
                    ),
                  ),

                // Featured Badge
                if (product.isFeatured)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, size: 10, color: Colors.amber),
                          SizedBox(width: 2),
                          Text(
                            "مميز",
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFFE11D48),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Brand Badge
                if (product.brand.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        border: Border.all(color: Colors.pink.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.brand,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.pink.shade800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details Area
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      if (product.supplierName != null)
                        Text(
                          "المورد: ${product.supplierName}",
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${price.toStringAsFixed(2)} ر.س",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 30,
                        child: ElevatedButton(
                          onPressed:
                              isImporting
                                  ? null
                                  : () => _handleImport(product.id, price),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(MaterialState.disabled))
                                return Colors.grey.shade300;
                              return null; // Use gradient logic via Container if needed, or simple color
                            }),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF43F5E), Color(0xFF9333EA)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child:
                                  isImporting
                                      ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.rocket_launch,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "إضافة للمتجر",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text(
            "لا توجد منتجات مطابقة",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// Extension Helper for Filter
extension IterableModifier<E> on Iterable<E> {
  Iterable<E> filter(bool Function(E) test) => where(test);
}
