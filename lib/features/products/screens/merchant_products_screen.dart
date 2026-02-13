import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:linyora_project/features/products/screens/product_details_screen.dart';
import 'package:linyora_project/features/subscriptions/screens/payment_Services.dart'; // تأكد من المسار
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

  // الإحصائيات الحقيقية
  int get _totalProducts => _products.length;
  int get _activeProducts =>
      _products.where((p) => p.status == 'active').length;

  // حساب المنتجات ذات المخزون المنخفض (أقل من 10 قطع في أي متغير)
  int get _lowStock {
    int count = 0;
    for (var p in _products) {
      // نفترض أن لديك Variants في المودل، إذا لم يكن، يمكنك تعديل الشرط
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('حذف المنتج'),
            content: const Text('هل أنت متأكد من حذف هذا المنتج نهائياً؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _productService.deleteProduct(id);
        _fetchProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحذف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
      }
    }
  }

  // --- منطق الترويج ---
  Future<void> _handlePromote(ProductModel product) async {
    // 1. جلب الباقات
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tiers = await _productService.getPromotionTiers();
      Navigator.pop(context); // إغلاق التحميل

      if (tiers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد باقات ترويج متاحة حالياً')),
        );
        return;
      }

      // 2. عرض نافذة اختيار الباقة
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder:
            (context) => _PromotionTiersSheet(
              product: product,
              tiers: tiers,
              onSelect: (tier) async {
                Navigator.pop(context); // إغلاق النافذة
                await _processPromotionPayment(product.id, tier.id);
              },
            ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  Future<void> _processPromotionPayment(int productId, int tierId) async {
    await _paymentService.promoteProduct(
      context: context,
      productId: productId,
      tierId: tierId,
      onSuccess: () {
        // عند نجاح الدفع
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ترويج المنتج بنجاح! 🚀'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchProducts(); // تحديث القائمة لعرض الشارة الجديدة
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'المنتجات',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      if (_products.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _products.length,
                          separatorBuilder:
                              (ctx, i) => const SizedBox(height: 12),
                          itemBuilder:
                              (ctx, index) =>
                                  _buildProductAccordion(_products[index]),
                        ),
                      const SizedBox(height: 40), // مسافة في الأسفل
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          "إجمالي المنتجات",
          _totalProducts.toString(),
          Icons.inventory_2,
          Colors.blue,
        ),
        _buildStatCard(
          "منتجات نشطة",
          _activeProducts.toString(),
          Icons.visibility,
          Colors.green,
        ),
        // _buildStatCard("مخزون منخفض", _lowStock.toString(), Icons.trending_down, Colors.amber),
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

  // أضف هذه الدالة لحل المشكلة
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

  // --- Product Accordion Item ---
  Widget _buildProductAccordion(ProductModel product) {
    // 1. منطق التحقق من الترويج
    // نفترض أن المودل يحتوي على حقل promotionEndsAt
    // إذا لم يكن موجوداً، يجب إضافته في ProductModel
    bool isPromoted = false;
    String promotionText = "";

    if (product.promotionEndsAt != null) {
      final endDate = DateTime.tryParse(product.promotionEndsAt!);
      if (endDate != null && endDate.isAfter(DateTime.now())) {
        isPromoted = true;
        final daysLeft = endDate.difference(DateTime.now()).inDays;
        promotionText =
            daysLeft > 0 ? "مروّج ($daysLeft يوم)" : "مروّج (ينتهي اليوم)";
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
                  : Colors.grey.shade200, // حدود ملونة للمروج
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
              // إذا كان مروجاً نعطيه إطاراً مميزاً
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
              _buildStatusBadge(product.status),

              // 2. شارة الترويج (Promoted Badge)
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
                    children: const [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Color(0xFFF43F5E),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "تفاصيل المنتج",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow("السعر", "${product.price} ر.س"),
                  if (product.brand != null)
                    _buildDetailRow("العلامة التجارية", product.brand!),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- أزرار التحكم ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 3. تفعيل زر المعاينة
                  _buildActionButton(
                    "معاينة",
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
                  // داخل دالة بناء زر التعديل
                  _buildActionButton(
                    "تعديل",
                    Icons.edit_outlined,
                    Colors.black87,
                    () async {
                      // 1. إظهار التحميل
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

                      // 2. جلب التفاصيل من السيرفر (للحصول على isDropshipping)
                      // ملاحظة: هذا الكائن سيحتوي على فئة واحدة فقط بسبب مشكلة الباك إند
                      final fetchedProduct = await _productService
                          .getProductById(product.id);

                      Navigator.pop(context); // إخفاء التحميل

                      if (fetchedProduct != null) {
                        // 🔥🔥 الحل السحري هنا 🔥🔥
                        // نقوم بإنشاء نسخة جديدة تدمج البيانات:
                        // نأخذ كل شيء من (fetchedProduct) لأنه الأحدث
                        // لكن نأخذ (categoryIds) من (product) الموجود في القائمة لأنه الصحيح والكامل

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

                          // ✅ هنا نأخذ الفئات من القائمة (product) وليس من السيرفر (fetchedProduct)
                          // لأن القائمة تحتوي على [1, 2, 3] بينما السيرفر أعاد [3] فقط
                          categoryIds: product.categoryIds,

                          // ✅ ونأخذ حالة الدروب شيبينج من السيرفر
                          isDropshipping: fetchedProduct.isDropshipping,
                          originalProductId: fetchedProduct.originalProductId,
                          merchantId: fetchedProduct.merchantId,
                        );

                        // نرسل المنتج المدمج لصفحة التعديل
                        _navigateToAddEdit(product: mergedProduct);
                      } else {
                        // في حال فشل الاتصال، نستخدم البيانات المحلية
                        _navigateToAddEdit(product: product);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    "ترويج",
                    Icons.campaign,
                    const Color(0xFFF43F5E),
                    () => _handlePromote(product),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    "حذف",
                    Icons.delete_outline,
                    Colors.red,
                    () => _deleteProduct(product.id.toString()),
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

  Widget _buildStatusBadge(String status) {
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
        isActive ? "نشط" : "مسودة",
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            const Text(
              'لا توجد منتجات بعد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'ابدأ بإضافة منتجك الأول وابدأ البيع!',
              style: TextStyle(color: Colors.grey),
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
              label: const Text('إضافة منتج جديد'),
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

  const _PromotionTiersSheet({
    required this.product,
    required this.tiers,
    required this.onSelect,
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
              const Expanded(
                child: Text(
                  "ترويج المنتج",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            "اختر باقة للترويج لمنتج: ${product.name}",
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
                                "${tier.durationDays} يوم",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${tier.price.toInt()} ر.س",
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
