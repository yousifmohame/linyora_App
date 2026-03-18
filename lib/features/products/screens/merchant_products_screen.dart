import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:linyora_project/features/products/screens/product_details_screen.dart';
import 'package:linyora_project/features/subscriptions/screens/payment_Services.dart';

// ✅ 1. استيراد ملف الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../../../models/product_model.dart';
import '../../products/services/product_service.dart';
import 'add_edit_product_screen.dart';

class MerchantProductsScreen extends StatefulWidget {
  const MerchantProductsScreen({Key? key}) : super(key: key);

  @override
  State<MerchantProductsScreen> createState() => _MerchantProductsScreenState();
}

class _MerchantProductsScreenState extends State<MerchantProductsScreen> {
  final ProductService _productService = ProductService();
  final PaymentService _paymentService = PaymentService();

  List<ProductModel> _products = [];
  bool _isLoading = true;

  int get _totalProducts => _products.length;
  int get _activeProducts =>
      _products.where((p) => p.status == 'active').length;

  int get _lowStock {
    int count = 0;
    for (var p in _products) {
      bool isLow = false;
      // if (p.variants != null) {
      //   isLow = p.variants!.any((v) => v.stockQuantity < 10);
      // }
      if (isLow) count++;
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getMyProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorOccurredMsg}$e')),
      ); // ✅ مترجم
    }
  }

  Future<void> _deleteProduct(String id, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.deleteProductTitle), // ✅ مترجم
            content: Text(l10n.deleteProductContent), // ✅ مترجم
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancelBtn), // ✅ مترجم (ترجمناها سابقاً)
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n.delete,
                  style: const TextStyle(color: Colors.red),
                ), // ✅ مترجم (ترجمناها سابقاً)
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _productService.deleteProduct(id);
        _fetchProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deletedSuccessfullyMsg), // ✅ مترجم
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.deletionFailedMsg}$e')),
        ); // ✅ مترجم
      }
    }
  }

  // --- منطق الترويج ---
  Future<void> _handlePromote(
    ProductModel product,
    AppLocalizations l10n,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tiers = await _productService.getPromotionTiers();
      Navigator.pop(context);

      if (tiers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noPromotionTiersAvailableMsg)), // ✅ مترجم
        );
        return;
      }

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder:
            (context) => _PromotionTiersSheet(
              product: product,
              tiers: tiers,
              l10n: l10n, // ✅ تمرير l10n
              onSelect: (tier) async {
                Navigator.pop(context);
                await _processPromotionPayment(
                  product.id,
                  tier.id,
                  l10n,
                ); // ✅ تمرير l10n
              },
            ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorOccurredMsg}$e')),
      ); // ✅ مترجم
    }
  }

  Future<void> _processPromotionPayment(
    int productId,
    int tierId,
    AppLocalizations l10n,
  ) async {
    await _paymentService.promoteProduct(
      context: context,
      productId: productId,
      tierId: tierId,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productPromotedSuccessMsg), // ✅ مترجم
            backgroundColor: Colors.green,
          ),
        );
        _fetchProducts();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n.merchantProductsTitle, // ✅ مترجم
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFFF43F5E),
            ),
            onPressed: () => _navigateToAddEdit(),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF43F5E)),
              )
              : RefreshIndicator(
                onRefresh: _fetchProducts,
                color: const Color(0xFFF43F5E),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsGrid(l10n), // ✅ تمرير l10n
                      const SizedBox(height: 24),
                      if (_products.isEmpty)
                        _buildEmptyState(l10n) // ✅ تمرير l10n
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _products.length,
                          separatorBuilder:
                              (ctx, i) => const SizedBox(height: 12),
                          itemBuilder:
                              (ctx, index) => _buildProductAccordion(
                                _products[index],
                                l10n,
                              ), // ✅ تمرير l10n
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatsGrid(AppLocalizations l10n) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          l10n.totalProductsLabel, // ✅ مترجم
          _totalProducts.toString(),
          Icons.inventory_2,
          Colors.blue,
        ),
        _buildStatCard(
          l10n.activeProductsLabel, // ✅ مترجم
          _activeProducts.toString(),
          Icons.visibility,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductAccordion(ProductModel product, AppLocalizations l10n) {
    bool isPromoted = false;
    String promotionText = "";

    if (product.promotionEndsAt != null) {
      final endDate = DateTime.tryParse(product.promotionEndsAt!);
      if (endDate != null && endDate.isAfter(DateTime.now())) {
        isPromoted = true;
        final daysLeft = endDate.difference(DateTime.now()).inDays;
        promotionText =
            daysLeft > 0
                ? "${l10n.promotedLabel} ($daysLeft ${l10n.daysLabel})"
                : "${l10n.promotedLabel} (${l10n.endsTodayLabel})"; // ✅ مترجم (ديناميكي)
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isPromoted
                  ? const Color(0xFF9333EA).withOpacity(0.3)
                  : Colors.grey.shade200,
          width: isPromoted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isPromoted
                    ? const Color(0xFF9333EA).withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border:
                  isPromoted
                      ? Border.all(color: const Color(0xFF9333EA), width: 2)
                      : null,
              gradient: const LinearGradient(
                colors: [Color(0xFFF43F5E), Color(0xFF9333EA)],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.cover,
                errorWidget:
                    (c, u, e) => const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                    ),
              ),
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusBadge(product.status, l10n), // ✅ تمرير l10n

              if (isPromoted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF9333EA).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.campaign,
                        size: 12,
                        color: Color(0xFF9333EA),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        promotionText,
                        style: const TextStyle(
                          color: Color(0xFF9333EA),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              if (product.brand != null && product.brand!.isNotEmpty)
                _buildBadge(product.brand!, Icons.local_offer, Colors.grey),
            ],
          ),
          children: [
            const Divider(),
            if (product.description != null && product.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    product.description!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Color(0xFFF43F5E),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.productDetailsLabel, // ✅ مترجم
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    l10n.priceLabel,
                    "${product.price} ${l10n.currencySAR}",
                  ), // ✅ مترجم
                  if (product.brand != null)
                    _buildDetailRow(l10n.brandLabel, product.brand!), // ✅ مترجم
                ],
              ),
            ),

            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildActionButton(
                    l10n.previewBtn, // ✅ مترجم
                    Icons.visibility_outlined,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProductDetailsScreen(
                                productId: product.id.toString(),
                              ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    l10n.editBtn, // ✅ مترجم (ترجمناها سابقاً)
                    Icons.edit_outlined,
                    Colors.black87,
                    () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (c) => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFF43F5E),
                              ),
                            ),
                      );

                      final fetchedProduct = await _productService
                          .getProductById(product.id);
                      Navigator.pop(context);

                      if (fetchedProduct != null) {
                        final mergedProduct = ProductModel(
                          id: fetchedProduct.id,
                          name: fetchedProduct.name,
                          description: fetchedProduct.description,
                          imageUrl: fetchedProduct.imageUrl,
                          rating: fetchedProduct.rating,
                          reviewCount: fetchedProduct.reviewCount,
                          merchantName: fetchedProduct.merchantName,
                          isNew: fetchedProduct.isNew,
                          brand: fetchedProduct.brand,
                          status: fetchedProduct.status,
                          price: fetchedProduct.price,
                          compareAtPrice: fetchedProduct.compareAtPrice,
                          stock: fetchedProduct.stock,
                          variants: fetchedProduct.variants,
                          promotionEndsAt: fetchedProduct.promotionEndsAt,
                          categoryIds: product.categoryIds,
                          isDropshipping: fetchedProduct.isDropshipping,
                          originalProductId: fetchedProduct.originalProductId,
                          merchantId: fetchedProduct.merchantId,
                        );

                        _navigateToAddEdit(product: mergedProduct);
                      } else {
                        _navigateToAddEdit(product: product);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    l10n.promoteBtn, // ✅ مترجم
                    Icons.campaign,
                    const Color(0xFFF43F5E),
                    () => _handlePromote(product, l10n), // ✅ تمرير l10n
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    l10n.delete, // ✅ مترجم (سابقاً)
                    Icons.delete_outline,
                    Colors.red,
                    () => _deleteProduct(
                      product.id.toString(),
                      l10n,
                    ), // ✅ تمرير l10n
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    bool isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        isActive ? l10n.activeStatusLabel : l10n.draftStatusLabel, // ✅ مترجم
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF43F5E), Color(0xFF9333EA)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noProductsYetTitle, // ✅ مترجم
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.startAddingProductsMsg, // ✅ مترجم
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddEdit(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(l10n.addNewProductBtn), // ✅ مترجم
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddEdit({ProductModel? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)),
    ).then((_) => _fetchProducts());
  }
}

// --- Widget: نافذة اختيار باقات الترويج ---
class _PromotionTiersSheet extends StatelessWidget {
  final ProductModel product;
  final List<PromotionTier> tiers;
  final Function(PromotionTier) onSelect;
  final AppLocalizations l10n; // ✅ استقبال الترجمة

  const _PromotionTiersSheet({
    required this.product,
    required this.tiers,
    required this.onSelect,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: Color(0xFFF43F5E), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.promoteProductTitle, // ✅ مترجم
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            "${l10n.choosePackageForProductMsg}${product.name}", // ✅ مترجم
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: tiers.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tier = tiers[index];
                return GestureDetector(
                  onTap: () => onSelect(tier),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFF43F5E).withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF43F5E).withOpacity(0.05),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFF43F5E)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tier.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "${tier.durationDays} ${l10n.daysLabel}", // ✅ مترجم
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${tier.price.toInt()} ${l10n.currencySAR}", // ✅ عملة مترجمة
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF9333EA),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
