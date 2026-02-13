import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

// المودلز والخدمات
import 'package:linyora_project/models/product_model.dart';
import 'package:linyora_project/models/product_details_model.dart';
import 'package:linyora_project/features/products/widgets/related_products_section.dart';
import 'package:linyora_project/features/wishlist/providers/wishlist_provider.dart';
import 'package:linyora_project/features/cart/providers/cart_provider.dart';
import 'package:linyora_project/features/auth/providers/auth_provider.dart'; // ✅ هام للتحقق من الأدمن

// الشاشات
import 'package:linyora_project/features/cart/screens/cart_screen.dart';
import 'package:linyora_project/features/cart/screens/checkout_screen.dart';
import 'package:linyora_project/features/public_profiles/screens/merchant_profile_screen.dart';
import 'package:linyora_project/features/home/screens/notifications_screen.dart'; // ✅ للإشعارات
import 'package:linyora_project/features/home/screens/home_screen.dart'; // ✅ للعودة للرئيسية

import '../services/product_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({Key? key, required this.productId})
    : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();

  ProductDetailsModel? _product;
  ProductVariant? _selectedVariant;
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = true;
  bool _isDescriptionExpanded = false;

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
          if (product != null && product.variants.isNotEmpty) {
            _selectedVariant = product.variants.first;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateAverageRating() {
    if (_product == null || _product!.reviews.isEmpty) return 0.0;
    double total = _product!.reviews.fold(0, (sum, item) => sum + item.rating);
    return total / _product!.reviews.length;
  }

  void _shareProduct() {
    if (_product == null) return;
    final String productUrl = 'https://linyora.com/products/${_product!.id}';
    final String shareText =
        'شاهد هذا المنتج الرائع على Linyora: \n${_product!.name}\nبسعر: ${_selectedVariant?.price ?? 0} ﷼\n\n$productUrl';
    Share.share(shareText, subject: _product!.name);
  }

  void _addToCart({bool goToCheckout = false}) {
    if (_product == null) return;
    final productModel = _product!.toProductModel();
    Provider.of<CartProvider>(
      context,
      listen: false,
    ).addToCart(productModel, _quantity, _selectedVariant);

    if (goToCheckout) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
      );
    } else {
      _showAddToCartSuccessSheet();
    }
  }

  void _showAddToCartSuccessSheet() {
    final String image =
        (_selectedVariant != null && _selectedVariant!.images.isNotEmpty)
            ? _selectedVariant!.images.first
            : _product!.imageUrl;

    final double price = _selectedVariant?.price ?? _product!.price;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 280,
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text(
                    "تمت الإضافة إلى السلة",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget:
                          (context, url, error) =>
                              Container(color: Colors.grey[200]),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_product!.name, maxLines: 1),
                        Text(
                          "${price.toStringAsFixed(0)} ر.س",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("تابع التسوق"),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                      child: const Text("عرض السلة"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _parseColor(String? colorName) {
    if (colorName == null || colorName.isEmpty) return Colors.grey.shade200;
    final normalizedColor = colorName.trim().toLowerCase();
    if (normalizedColor.startsWith('#')) {
      try {
        final buffer = StringBuffer();
        if (normalizedColor.length == 7) buffer.write('ff');
        buffer.write(normalizedColor.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        return Colors.grey.shade200;
      }
    }
    const Map<String, Color> colorMap = {
      'white': Colors.white,
      'black': Colors.black,
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blue,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'brown': Colors.brown,
      'grey': Colors.grey,
      'beige': Color(0xFFF5F5DC),
      'navy': Color(0xFF000080),
      'maroon': Color(0xFF800000),
      'gold': Color(0xFFFFD700),
      'silver': Color(0xFFC0C0C0),
    };
    return colorMap[normalizedColor] ?? const Color(0xFFEEEEEE);
  }

  // ✅ 1. الـ SliverAppBar الجديد المطابق للرئيسية
  Widget _buildSliverAppBar() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isRealAdmin =
        authProvider.user != null && authProvider.user!.roleId == 1;

    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      // زر رجوع لأنه صفحة تفاصيل
      leading: const BackButton(color: Colors.black),
      title: GestureDetector(
        onTap: () {
          // العودة للرئيسية
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "INOYRA",
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Playfair Display',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 2.0,
              ),
            ),
            const Text(
              "L",
              style: TextStyle(
                color: Colors.pink,
                fontFamily: 'Playfair Display',
                fontWeight: FontWeight.w900,
                fontSize: 30,
                letterSpacing: 2.0,
              ),
            ),
            if (isRealAdmin)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "ADMIN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        // زر المشاركة (أضفناه هنا لأنه مهم في صفحة المنتج)
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black),
          onPressed: _shareProduct,
        ),
        // زر الإشعارات
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.black,
            size: 28,
          ),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const NotificationsScreen()),
              ),
        ),
        // زر السلة
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => const CartScreen()),
                      ),
                ),
                if (cart.items.isNotEmpty)
                  Positioned(
                    top: 3,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_product == null)
      return const Scaffold(body: Center(child: Text("المنتج غير متوفر")));

    bool hasDiscount = false;
    int discountPercent = 0;

    final double currentPrice = _selectedVariant?.price ?? _product!.price;
    final double? comparePrice = _selectedVariant?.compareAtPrice;

    if (comparePrice != null && comparePrice > currentPrice) {
      hasDiscount = true;
      discountPercent =
          ((comparePrice - currentPrice) / comparePrice * 100).round();
    }

    final double rating = _calculateAverageRating();
    final int reviewCount = _product!.reviews.length;

    final List<String> currentImages =
        (_selectedVariant != null && _selectedVariant!.images.isNotEmpty)
            ? _selectedVariant!.images
            : [_product!.imageUrl];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ✅ 1. البار العلوي
          _buildSliverAppBar(),

          // ✅ 2. معرض الصور (تم نقله إلى SliverToBoxAdapter)
          SliverToBoxAdapter(
            child: Container(
              height: 450, // نفس الارتفاع السابق
              color: Colors.white,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    itemCount: currentImages.length,
                    onPageChanged:
                        (index) => setState(() => _currentImageIndex = index),
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: currentImages[index],
                        fit: BoxFit.contain,
                        errorWidget:
                            (context, url, error) =>
                                const Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                  if (currentImages.length > 1)
                    Positioned(
                      bottom: 20,
                      child: Row(
                        children:
                            currentImages.asMap().entries.map((entry) {
                              return Container(
                                width: _currentImageIndex == entry.key ? 20 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _currentImageIndex == entry.key
                                          ? Colors.pink
                                          : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ✅ 3. باقي تفاصيل المنتج (تم الحفاظ عليها)
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // السعر
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currentPrice.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'ر.س',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (hasDiscount) ...[
                          Text(
                            comparePrice!.toStringAsFixed(0),
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
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
                    const SizedBox(height: 12),

                    // الاسم + زر المفضلة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _product!.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Consumer<WishlistProvider>(
                          builder: (context, wishlist, _) {
                            final isWishlisted = wishlist.isWishlisted(
                              _product!.id,
                            );
                            return GestureDetector(
                              onTap: () {
                                wishlist.toggleWishlist(
                                  _product!.toProductModel(),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isWishlisted
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      isWishlisted ? Colors.red : Colors.grey,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // التقييمات
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          reviewCount > 0
                              ? '${rating.toStringAsFixed(1)} ($reviewCount تقييم)'
                              : 'لا توجد تقييمات',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // الألوان
              if (_product!.variants.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "اختر المواصفات",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              _product!.variants.map((variant) {
                                bool isSelected =
                                    _selectedVariant?.id == variant.id;

                                if (variant.color != null &&
                                    variant.color!.isNotEmpty) {
                                  return GestureDetector(
                                    onTap:
                                        () => setState(() {
                                          _selectedVariant = variant;
                                          _currentImageIndex = 0;
                                        }),
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 12),
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? Colors.pink
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _parseColor(variant.color),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child:
                                            isSelected
                                                ? Icon(
                                                  Icons.check,
                                                  color:
                                                      _parseColor(
                                                                variant.color,
                                                              ) ==
                                                              Colors.white
                                                          ? Colors.black
                                                          : Colors.white,
                                                )
                                                : null,
                                      ),
                                    ),
                                  );
                                } else {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: ChoiceChip(
                                      label: Text(variant.name),
                                      selected: isSelected,
                                      onSelected:
                                          (val) => setState(
                                            () => _selectedVariant = variant,
                                          ),
                                      selectedColor: Colors.pink.shade100,
                                    ),
                                  );
                                }
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // التاجر
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFEEEEEE),
                      child: Icon(Icons.store, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "البائع: ${_product!.merchantName}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          "موثوق به",
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => MerchantProfileScreen(
                                  merchantId: _product!.merchantId,
                                ),
                          ),
                        );
                      },
                      child: const Text(
                        "زيارة المتجر",
                        style: TextStyle(color: Colors.pink),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // الوصف
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "وصف المنتج",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _product!.description,
                      maxLines: _isDescriptionExpanded ? null : 4,
                      overflow:
                          _isDescriptionExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.6),
                    ),
                    if (_product!.description.length > 150)
                      GestureDetector(
                        onTap:
                            () => setState(
                              () =>
                                  _isDescriptionExpanded =
                                      !_isDescriptionExpanded,
                            ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _isDescriptionExpanded ? "عرض أقل" : "اقرأ المزيد",
                            style: const TextStyle(color: Colors.pink),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // منتجات مشابهة
              RelatedProductsSection(currentProductId: _product!.id),

              const SizedBox(height: 8),

              ReviewsSection(reviews: _product!.reviews),

              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: SafeArea(
          child: Row(
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed:
                          () => setState(() {
                            if (_quantity > 1) _quantity--;
                          }),
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed:
                          () => setState(() {
                            final maxStock =
                                _selectedVariant?.stockQuantity ?? 100;
                            if (_quantity < maxStock) _quantity++;
                          }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _addToCart(goToCheckout: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.pink),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "أضف للسلة",
                    style: TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _addToCart(goToCheckout: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "شراء الآن",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewsSection extends StatelessWidget {
  final List<ProductReview> reviews;

  const ReviewsSection({Key? key, required this.reviews}) : super(key: key);

  // حساب توزيع النجوم (كم شخص أعطى 5 نجوم، 4 نجوم...)
  Map<int, int> _calculateStarDistribution() {
    Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in reviews) {
      int rating = review.rating.round();
      if (rating >= 1 && rating <= 5) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }
    }
    return distribution;
  }

  // حساب متوسط التقييم
  double _calculateAverage() {
    if (reviews.isEmpty) return 0.0;
    double total = reviews.fold(0, (sum, item) => sum + item.rating);
    return total / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        color: Colors.white,
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "لا توجد تقييمات بعد",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "كن أول من يقيم هذا المنتج!",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final double averageRating = _calculateAverage();
    final Map<int, int> distribution = _calculateStarDistribution();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "تقييمات العملاء",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // 1. قسم الملخص (الرقم الكبير + الشرائط)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العمود الأيمن: الرقم الكبير
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < averageRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${reviews.length} تقييم",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // العمود الأيسر: أشرطة التقدم
              Expanded(
                flex: 3,
                child: Column(
                  children:
                      [5, 4, 3, 2, 1].map((star) {
                        final count = distribution[star] ?? 0;
                        final percentage =
                            reviews.isEmpty ? 0.0 : count / reviews.length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                "$star",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                size: 10,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[100],
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "$count",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(thickness: 1, height: 1),
          ),

          // 2. قائمة التعليقات
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length > 5 ? 5 : reviews.length, // عرض أول 5 فقط
            separatorBuilder: (context, index) => const Divider(height: 30),
            itemBuilder: (context, index) {
              return _buildReviewItem(reviews[index]);
            },
          ),

          // زر عرض المزيد
          if (reviews.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // هنا يمكنك فتح صفحة تحتوي على كل التقييمات
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "عرض جميع التقييمات",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ويدجت لبناء كارت التعليق الواحد
  Widget _buildReviewItem(ProductReview review) {
    // تنسيق التاريخ
    String formattedDate = review.createdAt;
    try {
      final date = DateTime.parse(review.createdAt);
      formattedDate = DateFormat(
        'dd MMM yyyy',
        'en',
      ).format(date); // استخدم 'ar' إذا كانت المكتبة تدعم العربية
    } catch (_) {}

    // استخراج الحرف الأول للاسم
    String firstLetter =
        review.userName.isNotEmpty ? review.userName[0].toUpperCase() : "U";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // صورة المستخدم (دائرة بالحرف الأول)
            CircleAvatar(
              radius: 18,
              backgroundColor: _getColorForName(review.userName),
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // الاسم والتاريخ
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                // النجوم الصغيرة بجانب الاسم
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 12,
                    );
                  }),
                ),
              ],
            ),
            const Spacer(),
            Text(
              formattedDate,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (review.comment.isNotEmpty)
          Text(
            review.comment,
            style: const TextStyle(
              color: Color(0xFF444444),
              height: 1.5,
              fontSize: 14,
            ),
          ),

        // أزرار تفاعلية وهمية (للمنظر الجمالي فقط)
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.thumb_up_alt_outlined,
              size: 16,
              color: Colors.grey[400],
            ),
            const SizedBox(width: 4),
            Text(
              "مفيد",
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(width: 16),
            Text(
              "إبلاغ",
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ],
    );
  }

  // دالة لتوليد لون عشوائي ثابت بناءً على الاسم
  Color _getColorForName(String name) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final hash = name.codeUnits.fold(0, (sum, code) => sum + code);
    return colors[hash % colors.length].withOpacity(0.8);
  }
}
