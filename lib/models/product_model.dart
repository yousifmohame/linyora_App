import '../core/widgets/optimized_image.dart';

class ProductModel {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviewCount;

  final String merchantId;
  final String merchantName;

  final bool isNew;
  final String? brand;
  final String status;
  final double price;
  final double? compareAtPrice;
  final int stock;
  final List<ProductVariant> variants; // جعلتها غير null دائماً لتسهيل التعامل

  final String? promotionEndsAt;
  final List<int>? categoryIds;

  final bool isDropshipping;
  final int? originalProductId;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.merchantId,
    required this.merchantName,
    this.isNew = false,
    this.brand,
    this.status = 'active',
    required this.price,
    this.compareAtPrice,
    this.stock = 0,
    this.variants = const [], // Default empty list
    this.promotionEndsAt,
    this.categoryIds,
    this.isDropshipping = false,
    this.originalProductId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. معالجة المتغيرات (Variants) أولاً
    List<ProductVariant> variantsList = [];
    if (json['variants'] != null && json['variants'] is List) {
      variantsList =
          (json['variants'] as List)
              .map((v) => ProductVariant.fromJson(v))
              .toList();
    }

    // 2. إعداد القيم الافتراضية
    double displayPrice =
        double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    String displayImage = '';
    int totalStock = int.tryParse(json['stock']?.toString() ?? '0') ?? 0;

    // ✅ المتغير الذكي للخصم
    double? resolvedCompareAtPrice;

    // محاولة قراءة الخصم من الجذر أولاً
    if (json['compare_at_price'] != null) {
      resolvedCompareAtPrice = double.tryParse(
        json['compare_at_price'].toString(),
      );
    }

    // 3. المنطق الذكي: إذا وجدنا متغيرات، نأخذ البيانات منها إذا كانت البيانات الرئيسية ناقصة
    if (variantsList.isNotEmpty) {
      final first = variantsList.first;

      // إذا السعر الرئيسي 0، خذ سعر الفارينت
      if (displayPrice == 0) displayPrice = first.price;

      // ✅ إذا لم نجد خصم في الجذر، نبحث في الفارينت
      if (resolvedCompareAtPrice == null) {
        resolvedCompareAtPrice = first.compareAtPrice;
      }

      // الصورة
      if (first.images.isNotEmpty) displayImage = first.images.first;

      // المخزون التراكمي
      totalStock = variantsList.fold(
        0,
        (sum, item) => sum + item.stockQuantity,
      );
    }

    // 4. معالجة الصورة إذا لم نأخذها من الفارينت
    if (displayImage.isEmpty) {
      if (json['image_url'] != null) {
        displayImage = json['image_url'].toString();
      } else if (json['images'] != null &&
          (json['images'] as List).isNotEmpty) {
        displayImage = json['images'][0].toString();
      }
    }

    // معالجة الفئات
    List<int> catIds = [];
    if (json['categoryIds'] != null && json['categoryIds'] is List) {
      catIds =
          (json['categoryIds'] as List)
              .map((e) => int.parse(e.toString()))
              .toList();
    }

    return ProductModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: displayImage,
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      reviewCount: int.tryParse(json['reviewCount']?.toString() ?? '0') ?? 0,

      merchantId:
          json['merchant_id']?.toString() ??
          json['merchantId']?.toString() ??
          '0',
      merchantName:
          json['merchant_name']?.toString() ??
          json['merchantName']?.toString() ??
          'Unknown',

      isNew: json['is_new'] == true || json['is_new'] == 1,
      brand: json['brand']?.toString(),
      status: json['status']?.toString() ?? 'active',

      price: displayPrice,
      compareAtPrice: resolvedCompareAtPrice, // ✅ استخدام القيمة المحسوبة

      stock: totalStock,
      variants: variantsList,
      promotionEndsAt: json['promotion_ends_at']?.toString(),
      categoryIds: catIds,
      isDropshipping:
          json['is_dropshipping'] == true || json['is_dropshipping'] == 1,
      originalProductId: int.tryParse(
        json['original_product_id']?.toString() ?? '',
      ),
    );
  }
}

class ProductVariant {
  final int id;
  final double price;
  final double? compareAtPrice;
  final int stockQuantity;
  final String? color;
  final String? size;
  final List<String> images;
  final String? sku;

  ProductVariant({
    required this.id,
    required this.price,
    this.compareAtPrice,
    required this.stockQuantity,
    this.color,
    this.size,
    required this.images,
    this.sku,
  });

  String get name {
    List<String> parts = [];
    if (color != null && color!.isNotEmpty) parts.add(color!);
    if (size != null && size!.isNotEmpty) parts.add(size!);
    return parts.isEmpty ? 'Default' : parts.join(' / ');
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];
    if (json['images'] != null && json['images'] is List) {
      imgs = (json['images'] as List).map((e) => e.toString()).toList();
    } else if (json['image'] != null) {
      imgs.add(json['image'].toString());
    }

    return ProductVariant(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      compareAtPrice:
          json['compare_at_price'] != null
              ? double.tryParse(json['compare_at_price'].toString())
              : null,
      stockQuantity:
          int.tryParse(
            json['stock_quantity']?.toString() ??
                json['stock']?.toString() ??
                '0',
          ) ??
          0,
      color: json['color']?.toString(),
      size: json['size']?.toString(),
      images: imgs,
      sku: json['sku']?.toString(),
    );
  }
}
