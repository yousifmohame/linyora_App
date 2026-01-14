import 'package:linyora_project/models/product_details_model.dart';
import '../core/utils/image_helper.dart';

class ProductModel {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String merchantName;
  final bool isNew;
  final String? brand;
  final String status;
  final double price;
  final String? promotionEndsAt;
  final double? compareAtPrice;
  final int stock;
  final List<ProductVariant>? variants;
  final List<int>? categoryIds;

  // حقول الدروب شيبينج
  final bool isDropshipping;
  final int? originalProductId;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.merchantName,
    this.isNew = false,
    this.brand,
    this.status = 'active',
    required this.price,
    this.compareAtPrice,
    this.stock = 0,
    this.variants,
    this.categoryIds,
    this.promotionEndsAt,
    this.isDropshipping = false,
    this.originalProductId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. استخراج المتغيرات (Variants)
    List<ProductVariant> variantsList = [];
    if (json['variants'] != null) {
      if (json['variants'] is List) {
        variantsList =
            (json['variants'] as List)
                .map((v) => ProductVariant.fromJson(v))
                .toList();
      }
    }

    // 2. تحديد البيانات الرئيسية
    double displayPrice = 0.0;
    double? displayComparePrice;
    String displayImage = '';
    int totalStock = 0;

    if (variantsList.isNotEmpty) {
      final first = variantsList.first;
      displayPrice = first.price;
      displayComparePrice = first.compareAtPrice;
      if (first.images.isNotEmpty) displayImage = first.images.first;
      totalStock = variantsList.fold(
        0,
        (sum, item) => sum + item.stockQuantity,
      );
    } else {
      displayPrice = (json['price'] as num?)?.toDouble() ?? 0.0;
      if (json['image_url'] != null) {
        displayImage = json['image_url'].toString();
      } else if (json['image'] != null) {
        displayImage = json['image'].toString();
      }
      totalStock = (json['stock'] as num?)?.toInt() ?? 0;
    }

    // -----------------------------------------------------------
    // ✅ 3. الحل هنا: معالجة الفئات بذكاء (List أو Single Value)
    // -----------------------------------------------------------
    List<int> catIds = [];

    // الحالة أ: إذا جاءت كقائمة (categoryIds)
    if (json['categoryIds'] != null && json['categoryIds'] is List) {
      catIds =
          (json['categoryIds'] as List)
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e > 0)
              .toList();
    }
    // الحالة ب: إذا جاءت ككائنات (categories)
    else if (json['categories'] != null && json['categories'] is List) {
      catIds =
          (json['categories'] as List)
              .map((e) => int.tryParse(e['id']?.toString() ?? '0') ?? 0)
              .where((e) => e > 0)
              .toList();
    }

    // ✅ الحالة ج (الحل لمشكلتك): إذا جاءت كقيمة مفردة (category_id)
    // الباك إند يرسل MAX(category_id) كقيمة واحدة، لذا نلتقطها هنا
    if (catIds.isEmpty && json['category_id'] != null) {
      int? singleId = int.tryParse(json['category_id'].toString());
      if (singleId != null && singleId > 0) {
        catIds.add(singleId);
      }
    }
    // -----------------------------------------------------------

    // 4. تحديد حالة الدروب شيبينج
    bool isDropshippingProduct = false;
    if (json['is_dropshipping'] != null) {
      isDropshippingProduct =
          json['is_dropshipping'] == true ||
          json['is_dropshipping'] == 1 ||
          json['is_dropshipping'].toString() == '1';
    } else if (json['supplier_id'] != null) {
      isDropshippingProduct = true;
    }

    return ProductModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: ImageHelper.getValidUrl(displayImage),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      merchantName:
          json['merchantName']?.toString() ?? json['brand']?.toString() ?? '',
      isNew: json['is_new'] == true,
      promotionEndsAt: json['promotion_ends_at']?.toString(),
      brand: json['brand']?.toString(),
      status: json['status']?.toString() ?? 'active',
      price: displayPrice,
      compareAtPrice: displayComparePrice,
      stock: totalStock,
      variants: variantsList,
      categoryIds: catIds, // ✅ الآن ستحتوي على القيمة حتى لو جاءت مفردة
      isDropshipping: isDropshippingProduct,
      originalProductId:
          int.tryParse(json['original_product_id']?.toString() ?? '') ??
          int.tryParse(json['supplier_product_id']?.toString() ?? ''),
    );
  }
}
