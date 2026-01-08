import 'package:flutter/material.dart';
// 1. استيراد الموديل والكارت
import '../../../models/product_model.dart';
import '../../shared/widgets/product_card.dart';
import '../../../models/product_details_model.dart';
import '../services/product_service.dart';

class RelatedProductsSection extends StatefulWidget {
  final int? categoryId;
  final int? merchantId;
  final int currentProductId;
  final String? title;

  const RelatedProductsSection({
    Key? key,
    this.categoryId,
    this.merchantId,
    required this.currentProductId,
    this.title,
  }) : super(key: key);

  @override
  State<RelatedProductsSection> createState() => _RelatedProductsSectionState();
}

class _RelatedProductsSectionState extends State<RelatedProductsSection> {
  final ProductService _productService = ProductService();
  List<ProductDetailsModel> _products = [];
  bool _isLoading = true;
  String _displayTitle = "";

  @override
  void initState() {
    super.initState();
    _fetchRelatedProducts();
  }

  Future<void> _fetchRelatedProducts() async {
    if (widget.title != null) {
      _displayTitle = widget.title!;
    } else if (widget.categoryId != null) {
      _displayTitle = "منتجات مشابهة";
    } else if (widget.merchantId != null) {
      _displayTitle = "المزيد من هذا المتجر";
    } else {
      _displayTitle = "وصل حديثاً";
    }

    try {
      final products = await _productService.getProducts(
        categoryId: widget.categoryId,
        merchantId: (widget.categoryId == null) ? widget.merchantId : null,
        limit: 6,
      );

      final filteredProducts =
          products.where((p) => p.id != widget.currentProductId).toList();

      if (mounted) {
        setState(() {
          _products = filteredProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // دالة مساعدة لتحويل ProductDetailsModel إلى ProductModel
  ProductModel _mapToProductModel(ProductDetailsModel detail) {
    // استخراج السعر والصورة من أول متغير (Variant)
    final firstVariant =
        detail.variants.isNotEmpty ? detail.variants.first : null;
    final price = firstVariant?.price ?? 0.0;
    final compareAtPrice = firstVariant?.compareAtPrice;
    final image =
        (firstVariant != null && firstVariant.images.isNotEmpty)
            ? firstVariant.images.first
            : '';

    // حساب متوسط التقييم
    double rating = 0.0;
    if (detail.reviews.isNotEmpty) {
      final totalRating = detail.reviews.fold(
        0.0,
        (sum, item) => sum + item.rating,
      );
      rating = totalRating / detail.reviews.length;
    }

    return ProductModel(
      id: detail.id,
      name: detail.name,
      description: detail.description,
      price: price,
      compareAtPrice: compareAtPrice,
      imageUrl: image,
      rating: rating,
      reviewCount: detail.reviews.length,
      merchantName: detail.merchantName,
      isNew: false, // يمكن تعديل هذا الشرط حسب تاريخ الإنشاء إذا توفر
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SizedBox(
          height: 280, // تعديل الارتفاع ليتناسب مع ProductCard
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder:
                (_, __) => Container(
                  width: 160,
                  margin: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
          ),
        ),
      );
    }

    if (_products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            _displayTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        SizedBox(
          height:
              320, // زيادة الارتفاع لأن ProductCard يحتوي على ظلال وتفاصيل أكثر
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
            ), // تقليل الحواف لأن الكارت لديه هامش
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final detailProduct = _products[index];
              // تحويل البيانات لاستخدام الكارت الموحد
              final productModel = _mapToProductModel(detailProduct);

              return ProductCard(
                product: productModel,
                width: 160, // تحديد العرض كما هو مطلوب
              );
            },
          ),
        ),
      ],
    );
  }
}
