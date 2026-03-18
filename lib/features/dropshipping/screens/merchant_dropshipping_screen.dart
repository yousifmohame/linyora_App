import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

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

  List<SupplierProduct> _allProducts = [];
  List<SupplierProduct> _filteredProducts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final Set<int> _importingIds = {};

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
    bool hasAccess = user?.subscription?.hasDropshippingAccess ?? false;

    if (hasAccess) {
      _fetchProducts();
    } else {
      setState(() => _isLoading = false);
    }
  }

  // ✅ تم تمرير l10n لمعالجة رسالة الفشل
  Future<void> _fetchProducts() async {
    setState(() {
      if (_allProducts.isEmpty) _isLoading = true;
      _isRefreshing = true;
    });

    try {
      final products = await _service.getSupplierProducts();

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
          _applyFilters();
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToLoadProductsMsg)),
        ); // ✅ مترجم
      }
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

  // ✅ تمرير l10n لترجمة رسائل الاستيراد
  Future<void> _handleImport(
    int id,
    double price,
    AppLocalizations l10n,
  ) async {
    setState(() => _importingIds.add(id));
    try {
      await _service.importProduct(id, price);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productAddedSuccessfullyMsg), // ✅ مترجم
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = l10n.importFailedMsg; // ✅ مترجم
        Color snackBarColor = Colors.red;

        final errorString = e.toString().toLowerCase();

        if (errorString.contains('exist') ||
            errorString.contains('duplicate') ||
            errorString.contains('already') ||
            errorString.contains('موجود مسبقا')) {
          errorMessage = l10n.productAlreadyExistsMsg; // ✅ مترجم
          snackBarColor = Colors.orange;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
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

    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    if (!hasAccess && !_isLoading) {
      return _buildSubscriptionGate(l10n); // ✅ تمرير l10n
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1F2), Color(0xFFF3E8FF)],
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildHeader(l10n), // ✅ تمرير l10n
                              const SizedBox(height: 20),
                              _buildStatsCards(l10n), // ✅ تمرير l10n
                              const SizedBox(height: 20),
                              _buildFilters(l10n), // ✅ تمرير l10n
                            ],
                          ),
                        ),
                      ),

                      _filteredProducts.isEmpty
                          ? SliverToBoxAdapter(
                            child: _buildEmptyState(l10n),
                          ) // ✅ تمرير l10n
                          : SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.65,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildProductCard(
                                  _filteredProducts[index],
                                  l10n,
                                ), // ✅ تمرير l10n
                                childCount: _filteredProducts.length,
                              ),
                            ),
                          ),

                      const SliverToBoxAdapter(child: SizedBox(height: 30)),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionGate(AppLocalizations l10n) {
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
                  Text(
                    l10n.exclusiveContentTitle, // ✅ مترجم
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.exclusiveDropshippingDesc, // ✅ مترجم
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
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
                      label: Text(l10n.upgradePackageBtn), // ✅ مترجم
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

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.dropshippingMarketTitle, // ✅ مترجم
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.transparent,
            shadows: [Shadow(offset: Offset(0, -5), color: Colors.black)],
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFFF43F5E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.exploreThousandsProductsDesc, // ✅ مترجم
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsCards(AppLocalizations l10n) {
    int total = _allProducts.length;
    int featured = _allProducts.where((p) => p.isFeatured).length;
    int suppliers = _allProducts.map((p) => p.supplierName).toSet().length;

    return Row(
      children: [
        _buildStatItem(total, l10n.totalProducts, Colors.pink), // ✅ مترجم
        const SizedBox(width: 8),
        _buildStatItem(
          featured,
          l10n.featuredProducts,
          Colors.purple,
        ), // ✅ مترجم
        const SizedBox(width: 8),
        _buildStatItem(suppliers, l10n.suppliers, Colors.blue), // ✅ مترجم
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (val) {
              _searchTerm = val;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: l10n.searchProductHint, // ✅ مترجم
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
                                    c == 'all' ? l10n.allCategories : c,
                                    style: const TextStyle(fontSize: 13),
                                  ), // ✅ مترجم
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

  Widget _buildProductCard(SupplierProduct product, AppLocalizations l10n) {
    final firstVariant =
        product.variants.isNotEmpty ? product.variants.first : null;
    final String imageUrl =
        (firstVariant != null && firstVariant.images.isNotEmpty)
            ? firstVariant.images.first
            : '';
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
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 10, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            l10n.featuredBadgeText,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFFE11D48),
                              fontWeight: FontWeight.bold,
                            ),
                          ), // ✅ مترجم
                        ],
                      ),
                    ),
                  ),

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
                          "${l10n.supplierPrefix}${product.supplierName}", // ✅ مترجم ومدمج
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
                        "${price.toStringAsFixed(2)} ${l10n.currencySAR}", // ✅ عملة مترجمة
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
                                  : () => _handleImport(
                                    product.id,
                                    price,
                                    l10n,
                                  ), // ✅ تمرير l10n
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
                              return null;
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
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.rocket_launch,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.addToStoreBtn,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ), // ✅ مترجم
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            l10n.noResultsFoundMsg, // ✅ مترجم (مستخدم سابقاً)
            style: const TextStyle(
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

extension IterableModifier<E> on Iterable<E> {
  Iterable<E> filter(bool Function(E) test) => where(test);
}
