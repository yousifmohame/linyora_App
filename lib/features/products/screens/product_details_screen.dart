import 'package:flutter/material.dart';
import 'package:linyora_project/features/public_profiles/screens/merchant_profile_screen.dart';
import 'package:linyora_project/models/product_details_model.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

// تأكد من المسارات الصحيحة
import 'package:linyora_project/features/products/widgets/related_products_section.dart';
import 'package:linyora_project/features/wishlist/providers/wishlist_provider.dart';
import 'package:linyora_project/models/product_model.dart'; // الموديل العام
import '../../cart/providers/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';
import '../../cart/screens/checkout_screen.dart';
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

  // --- 1. دالة لتحويل بيانات التفاصيل إلى ProductModel للمفضلة ---
  ProductModel _createProductModelForWishlist() {
    if (_product == null || _selectedVariant == null) {
      // ارجاع كائن فارغ أو معالجة الخطأ (نظرياً لن يحدث لأن الزر لا يظهر إلا بعد التحميل)
      throw Exception("Product not loaded yet");
    }

    return ProductModel(
      id: _product!.id,
      name: _product!.name,
      description: _product!.description,
      // نستخدم سعر وصورة المتغير المختار حالياً
      price: _selectedVariant!.price,
      compareAtPrice: _selectedVariant!.compareAtPrice,
      imageUrl:
          _selectedVariant!.images.isNotEmpty
              ? _selectedVariant!.images.first
              : '',
      // حساب التقييم الحالي ليتم تخزينه
      rating: _calculateAverageRating(),
      reviewCount: _product!.reviews.length,
      merchantName: _product!.merchantName,
      isNew: false, // يمكن تعديل المنطق هنا
    );
  }

  // --- 2. دالة لحساب متوسط التقييم ---
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
    if (_product == null || _selectedVariant == null) return;

    Provider.of<CartProvider>(
      context,
      listen: false,
    ).addToCart(_product!, _selectedVariant!, _quantity);

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
                      imageUrl: _selectedVariant!.images.first,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_product!.name, maxLines: 1),
                        Text(
                          "${_selectedVariant!.price} ر.س",
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

  Color _parseColor(String colorName) {
    // 1. تنظيف النص: حذف المسافات وتحويل الأحرف لصغيرة
    final normalizedColor = colorName.trim().toLowerCase();

    // 2. التحقق مما إذا كان المدخل كود Hex (مثلاً #FF0000)
    if (normalizedColor.startsWith('#')) {
      try {
        final buffer = StringBuffer();
        if (normalizedColor.length == 7)
          buffer.write('ff'); // إضافة Alpha إذا لم يوجد
        buffer.write(normalizedColor.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        return Colors.grey.shade200; // لون احتياطي في حال الخطأ
      }
    }

    // 3. قاموس الألوان الموسع (يغطي الألوان الشائعة في الملابس والمنتجات)
    const Map<String, Color> colorMap = {
      // الألوان الأساسية
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
      'gray': Colors.grey,

      // ألوان الموضة والتجارة الإلكترونية
      'beige': Color(0xFFF5F5DC), // بيج
      'ivory': Color(0xFFFFFFF0), // عاجي
      'cream': Color(0xFFFFFDD0), // كريمي
      'off white': Color(0xFFFAF9F6), // أوف وايت
      'navy': Color(0xFF000080), // كحلي
      'maroon': Color(0xFF800000), // مارون / عودي
      'burgundy': Color(0xFF800020), // برغندي
      'olive': Color(0xFF808000), // زيتوني
      'teal': Color(0xFF008080), // تركواز غامق
      'cyan': Colors.cyan, // سماوي
      'turquoise': Color(0xFF40E0D0), // تركواز
      'gold': Color(0xFFFFD700), // ذهبي
      'silver': Color(0xFFC0C0C0), // فضي
      'bronze': Color(0xFFCD7F32), // برونزي
      'mustard': Color(0xFFFFDB58), // خردلي
      'khaki': Color(0xFFF0E68C), // كاكي
      'coral': Color(0xFFFF7F50), // مرجاني
      'peach': Color(0xFFFFE5B4), // خوخي
      'lavender': Color(0xFFE6E6FA), // لافندر
      'mauve': Color(0xFFE0B0FF), // بنفسجي فاتح
      'charcoal': Color(0xFF36454F), // فحم
      'indigo': Colors.indigo, // نيلي
      'lime': Colors.lime, // ليموني
      'tan': Color(0xFFD2B48C), // تان (بني فاتح)
    };

    // 4. إرجاع اللون الموجود في القاموس، أو رمادي فاتح كقيمة افتراضية
    return colorMap[normalizedColor] ?? const Color(0xFFEEEEEE);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_product == null)
      return const Scaffold(body: Center(child: Text("المنتج غير متوفر")));

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

    // حساب التقييم الحقيقي
    final double rating = _calculateAverageRating();
    final int reviewCount = _product!.reviews.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 450.0,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              _product!.name,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.black),
                onPressed: _shareProduct,
              ),
              IconButton(
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.black,
                ),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    PageView.builder(
                      itemCount: _selectedVariant?.images.length ?? 0,
                      onPageChanged:
                          (index) => setState(() => _currentImageIndex = index),
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: _selectedVariant!.images[index],
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                    Positioned(
                      bottom: 20,
                      child: Row(
                        children:
                            _selectedVariant!.images.asMap().entries.map((
                              entry,
                            ) {
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
          ),

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
                          '${_selectedVariant?.price.toStringAsFixed(0)}',
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
                            '${_selectedVariant?.compareAtPrice?.toStringAsFixed(0)}',
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

                    // الاسم + زر المفضلة الحقيقي (باستخدام Provider)
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

                        // --- زر المفضلة الحقيقي ---
                        Consumer<WishlistProvider>(
                          builder: (context, wishlist, _) {
                            // 1. التحقق من الحالة في البروفايدر
                            final isWishlisted = wishlist.isWishlisted(
                              _product!.id,
                            );

                            return GestureDetector(
                              onTap: () {
                                // 2. استدعاء دالة التحويل لإنشاء ProductModel وإضافته
                                final productModel =
                                    _createProductModelForWishlist();
                                wishlist.toggleWishlist(productModel);
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

                    // التقييمات الحقيقية
                    Row(
                      children: [
                        // رسم النجوم بناءً على المتوسط
                        ...List.generate(5, (index) {
                          if (index < rating.floor()) {
                            return const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            );
                          } else if (index < rating &&
                              (rating - index) >= 0.5) {
                            return const Icon(
                              Icons.star_half,
                              color: Colors.amber,
                              size: 18,
                            );
                          } else {
                            return const Icon(
                              Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }
                        }),
                        const SizedBox(width: 8),
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

              // قسم الألوان
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "اختر اللون",
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
                                                  _parseColor(variant.color) ==
                                                          Colors.white
                                                      ? Colors.black
                                                      : Colors.white,
                                            )
                                            : null,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // قسم التاجر
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
                        // التأكد من أن المنتج تم تحميله لتجنب الأخطاء
                        if (_product != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MerchantProfileScreen(
                                    // تحويل الـ ID من int إلى String ليناسب الشاشة
                                    merchantId: _product!.merchantId.toString(),
                                  ),
                            ),
                          );
                        }
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

              // المنتجات المشابهة
              RelatedProductsSection(
                merchantId: _product!.merchantId,
                currentProductId: _product!.id,
              ),

              const SizedBox(height: 100),
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
                            if (_selectedVariant != null &&
                                _quantity < _selectedVariant!.stockQuantity)
                              _quantity++;
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
