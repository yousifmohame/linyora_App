import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  // الإحصائيات
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
      if (mounted)
        setState(() {
          _products = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(int id) async {
    try {
      await _service.deleteProduct(id);
      _loadProducts(); // تحديث
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم الحذف")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("فشل الحذف")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // فتح الفورم في صفحة جديدة، وإذا تم الحفظ نحدث القائمة
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
        label: const Text("منتج جديد"),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // الإحصائيات
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "إجمالي المنتجات",
                          "$totalProducts",
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          "الأصناف",
                          "$totalVariants",
                          Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          "مخزون منخفض",
                          "$lowStock",
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // قائمة المنتجات
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_products.isEmpty)
                    const Center(child: Text("لا توجد منتجات"))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _products.length,
                      itemBuilder: (ctx, i) {
                        final product = _products[i];
                        return _buildProductItem(product);
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
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(SupplierProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
          subtitle: Text("${product.variants.length} ألوان"),
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
                onPressed: () => _deleteProduct(product.id!),
              ),
            ],
          ),
          children:
              product.variants
                  .map(
                    (v) => ListTile(
                      dense: true,
                      title: Text("لون: ${v.color}"),
                      subtitle: Text(
                        "المخزون: ${v.stockQuantity} | التكلفة: ${v.costPrice}",
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
