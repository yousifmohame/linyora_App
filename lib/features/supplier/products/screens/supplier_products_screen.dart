import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import 'package:linyora_project/features/supplier/products/models/supplier_models.dart';
import 'package:linyora_project/features/supplier/products/services/supplier_products_service.dart';

import 'supplier_product_form.dart';

class SupplierProductsScreen extends StatefulWidget {
  const SupplierProductsScreen({Key? key}) : super(key: key);

  @override
  State<SupplierProductsScreen> createState() => _SupplierProductsScreenState();
}

class _SupplierProductsScreenState extends State<SupplierProductsScreen> {
  final SupplierProductsService _service = SupplierProductsService();
  List<SupplierProduct> _products = [];
  bool _isLoading = true;

  int get totalProducts => _products.length;
  int get totalVariants =>
      _products.fold(0, (sum, p) => sum + p.variants.length);
  int get lowStock => _products.fold(
    0,
    (sum, p) => sum + p.variants.where((v) => v.stockQuantity < 10).length,
  );

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await _service.getProducts();
      if (mounted) {
        setState(() {
          _products = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(int id, AppLocalizations l10n) async {
    // ✅ تمرير l10n
    try {
      await _service.deleteProduct(id);
      _loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deletedSuccessfullyMsg),
        ), // ✅ مترجم (سابقاً)
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deletionFailedMsg)), // ✅ مترجم (سابقاً)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SupplierProductFormScreen(),
            ),
          );
          if (result == true) _loadProducts();
        },
        backgroundColor: const Color(0xFFF105C6),
        icon: const Icon(Icons.add),
        label: Text(l10n.newProductBtn), // ✅ مترجم (سابقاً)
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          l10n.totalProducts, // ✅ مترجم (سابقاً)
                          "$totalProducts",
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          l10n.totalVariantsLabel, // ✅ مترجم
                          "$totalVariants",
                          Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          l10n.lowStockLabel, // ✅ مترجم
                          "$lowStock",
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_products.isEmpty)
                    Center(
                      child: Text(l10n.noProductsYetMsg),
                    ) // ✅ مترجم (سابقاً)
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _products.length,
                      itemBuilder: (ctx, i) {
                        final product = _products[i];
                        return _buildProductItem(product, l10n); // ✅ تمرير l10n
                      },
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(SupplierProduct product, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  product.variants.isNotEmpty &&
                          product.variants.first.images.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: product.variants.first.images.first,
                        fit: BoxFit.cover,
                      )
                      : const Icon(Icons.image),
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "${product.variants.length}${l10n.colorsCountSuffix}",
          ), // ✅ مترجم ومدمج
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () async {
                  bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => SupplierProductFormScreen(product: product),
                    ),
                  );
                  if (result == true) _loadProducts();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed:
                    () => _deleteProduct(product.id!, l10n), // ✅ تمرير l10n
              ),
            ],
          ),
          children:
              product.variants
                  .map(
                    (v) => ListTile(
                      dense: true,
                      title: Text("${l10n.colorLabel}${v.color}"), // ✅ مترجم
                      subtitle: Text(
                        "${l10n.stockLabel}${v.stockQuantity} | ${l10n.costLabel}${v.costPrice}", // ✅ مترجم
                      ),
                      trailing:
                          v.images.isNotEmpty
                              ? SizedBox(
                                width: 30,
                                height: 30,
                                child: CachedNetworkImage(
                                  imageUrl: v.images.first,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : null,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
