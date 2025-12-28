import 'package:flutter/material.dart';
import 'package:linyora_project/features/cart/screens/cart_screen.dart';
import 'package:provider/provider.dart';
import '../../cart/providers/cart_provider.dart'; // تأكد من المسار
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/color_helper.dart'; // افترض وجود مساعد للألوان
import '../../cart/services/cart_service.dart'; // تأكد من المسار
import '../services/product_service.dart';
import '../../../models/product_details_model.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({Key? key, required this.productId})
    : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ProductService _productService = ProductService();
  // final CartService _cartService = CartService(); // استخدم البروفايدر إذا كان لديك

  ProductDetailsModel? _product;
  ProductVariant? _selectedVariant;
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = true;
  bool _isWishlisted = false; // يمكنك جلب حالتها الحقيقية من API منفصل

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final product = await _productService.getProductDetails(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
          // تعيين المتغير الافتراضي (الأول)
          if (product != null && product.variants.isNotEmpty) {
            _selectedVariant = product.variants.first;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addToCart() {
    if (_product == null || _selectedVariant == null) return;

    // استدعاء دالة الإضافة من البروفايدر
    // listen: false لأننا هنا ننفذ دالة ولا نستمع للتغييرات داخل هذه الدالة
    Provider.of<CartProvider>(
      context,
      listen: false,
    ).addToCart(_product!, _selectedVariant!, _quantity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            const Text('تمت الإضافة إلى السلة بنجاح'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating, // يجعلها عائمة
        action: SnackBarAction(
          label: 'عرض السلة',
          textColor: Colors.white,
          onPressed: () {
            // الانتقال لصفحة السلة (تأكد من وجود المسار)
            // Navigator.pushNamed(context, '/cart');
            // أو
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CartScreen()),
            );
          },
        ),
      ),
    );
  }

  Color _parseColor(String colorName) {
    // دالة بسيطة لتحويل أسماء الألوان لـ Color objects
    // يفضل استخدام مكتبة أو Map متكامل
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("المنتج غير موجود")),
      );
    }

    // حساب الخصم
    bool hasDiscount = false;
    int discountPercent = 0;
    if (_selectedVariant != null &&
        _selectedVariant!.compareAtPrice != null &&
        _selectedVariant!.compareAtPrice! > _selectedVariant!.price) {
      hasDiscount = true;
      discountPercent =
          ((_selectedVariant!.compareAtPrice! - _selectedVariant!.price) /
                  _selectedVariant!.compareAtPrice! *
                  100)
              .round();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header (Back & Share) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isWishlisted ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => _isWishlisted = !_isWishlisted);
                          // استدعاء API الويش ليست هنا
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          // ميزة المشاركة
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Image Gallery ---
                    SizedBox(
                      height: 350,
                      child: PageView.builder(
                        itemCount: _selectedVariant?.images.length ?? 0,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Hero(
                              tag: 'product_${_product!.id}',
                              child: CachedNetworkImage(
                                imageUrl: _selectedVariant!.images[index],
                                fit: BoxFit.contain,
                                placeholder:
                                    (context, url) =>
                                        Container(color: Colors.grey[100]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // نقاط الصور (Indicators)
                    if ((_selectedVariant?.images.length ?? 0) > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            _selectedVariant!.images.asMap().entries.map((
                              entry,
                            ) {
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _currentImageIndex == entry.key
                                          ? Colors.pink
                                          : Colors.grey.withOpacity(0.4),
                                ),
                              );
                            }).toList(),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Merchant Name ---
                          Row(
                            children: [
                              const Icon(
                                Icons.store,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _product!.merchantName,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // --- Product Name ---
                          Text(
                            _product!.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // --- Price & Discount ---
                          Row(
                            children: [
                              Text(
                                '${_selectedVariant?.price.toStringAsFixed(2)} ر.س',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (hasDiscount) ...[
                                Text(
                                  '${_selectedVariant?.compareAtPrice?.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$discountPercent% خصم',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),

                          // --- Colors (Variants) ---
                          if (_product!.variants.length > 1) ...[
                            const Text(
                              "اختر اللون",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              children:
                                  _product!.variants.map((variant) {
                                    final isSelected =
                                        _selectedVariant?.id == variant.id;
                                    return GestureDetector(
                                      onTap:
                                          () => setState(() {
                                            _selectedVariant = variant;
                                            _currentImageIndex = 0;
                                          }),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? const Color(0xFFF105C6)
                                                    : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: _parseColor(variant.color),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child:
                                              isSelected
                                                  ? const Icon(
                                                    Icons.check,
                                                    size: 18,
                                                    color: Colors.white,
                                                  )
                                                  : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // --- Description ---
                          const Text(
                            "الوصف",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _product!.description,
                            style: const TextStyle(
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // --- Features Grid (Static as per design) ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildFeatureItem(
                                Icons.local_shipping_outlined,
                                "شحن سريع",
                              ),
                              _buildFeatureItem(
                                Icons.verified_user_outlined,
                                "ضمان الجودة",
                              ),
                              _buildFeatureItem(
                                Icons.refresh_outlined,
                                "إرجاع مجاني",
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // --- Reviews Preview ---
                          if (_product!.reviews.isNotEmpty) ...[
                            const Divider(),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "التقييمات (${_product!.reviews.length})",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_left,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            // يمكنك إضافة قائمة مراجعات مصغرة هنا
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Bottom Action Bar ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quantity
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () {
                            if (_selectedVariant != null &&
                                _quantity < _selectedVariant!.stockQuantity) {
                              setState(() => _quantity++);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          (_selectedVariant?.stockQuantity ?? 0) > 0
                              ? _addToCart
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        (_selectedVariant?.stockQuantity ?? 0) > 0
                            ? "إضافة للسلة"
                            : "نفذت الكمية",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.pink[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.pink, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
