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
  final double? compareAtPrice;
  final int stock;
  final List<ProductVariant>? variants;
  final List<int>? categoryIds;

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
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // ✅ 1. استخراج المتغيرات (Variants) بشكل آمن
    List<ProductVariant> variantsList = [];
    if (json['variants'] != null) {
      if (json['variants'] is List) {
        variantsList =
            (json['variants'] as List)
                .map((v) => ProductVariant.fromJson(v))
                .toList();
      } else if (json['variants'] is Map) {
        // حالة نادرة: إذا جاءت المتغيرات كـ Map بدلاً من List
        // (Map<String, dynamic> يتم تحويل قيمها إلى List)
        (json['variants'] as Map<String, dynamic>).forEach((key, value) {
          variantsList.add(ProductVariant.fromJson(value));
        });
      }
    }

    // 2. تحديد البيانات الرئيسية للعرض
    double displayPrice = 0.0;
    double? displayComparePrice;
    String displayImage = '';
    int totalStock = 0;

    if (variantsList.isNotEmpty) {
      final first = variantsList.first;
      displayPrice = first.price;
      displayComparePrice = first.compareAtPrice;
      if (first.images.isNotEmpty) {
        displayImage = first.images.first;
      }
      totalStock = variantsList.fold(
        0,
        (sum, item) => sum + item.stockQuantity,
      );
    } else {
      displayPrice = double.tryParse(json['price'].toString()) ?? 0.0;
      if (json['image_url'] != null) {
        displayImage = json['image_url'].toString();
      } else if (json['image'] != null) {
        displayImage = json['image'].toString();
      }
      totalStock = int.tryParse(json['stock'].toString()) ?? 0;
    }

    String merchant = json['merchantName'] ?? json['brand'] ?? '';
    String brandName = json['brand'] ?? '';

    // ✅ 3. معالجة الفئات بشكل آمن
    List<int> catIds = [];
    if (json['categoryIds'] != null && json['categoryIds'] is List) {
      catIds =
          (json['categoryIds'] as List)
              .map((e) => int.parse(e.toString()))
              .toList();
    } else if (json['categories'] != null && json['categories'] is List) {
      catIds =
          (json['categories'] as List)
              .map((e) => int.parse(e['id'].toString()))
              .toList();
    }

    // 4. حساب "جديد"
    bool isNewProduct = false;
    if (json['created_at'] != null) {
      final createdAt = DateTime.tryParse(json['created_at'].toString());
      if (createdAt != null) {
        isNewProduct = DateTime.now().difference(createdAt).inDays < 7;
      }
    }

    return ProductModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: ImageHelper.getValidUrl(displayImage),
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      reviewCount: int.tryParse(json['reviewCount'].toString()) ?? 0,
      merchantName: merchant,
      isNew: isNewProduct,
      brand: brandName,
      status: json['status'] ?? 'active',
      price: displayPrice,
      compareAtPrice: displayComparePrice,
      stock: totalStock,
      variants: variantsList,
      categoryIds: catIds,
    );
  }
}
