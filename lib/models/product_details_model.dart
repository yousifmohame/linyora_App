import 'package:linyora_project/models/product_model.dart'; // تأكد من صحة المسار

class ProductDetailsModel {
  final int id;
  final String name;
  final String description;
  final String merchantId;
  final String merchantName;
  final bool isDropshipping;
  final List<ProductVariant> variants;
  final double? avgRating;

  // ✅ قائمة التقييمات
  final List<ProductReview> reviews;

  final String imageUrl;
  final double price;

  ProductDetailsModel({
    required this.id,
    required this.name,
    required this.description,
    required this.merchantId,
    required this.merchantName,
    required this.isDropshipping,
    required this.variants,
    required this.reviews,
    required this.imageUrl,
    required this.price,
    this.avgRating,
  });

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    // 1. معالجة المتغيرات (Variants)
    List<ProductVariant> variantsList = [];
    if (json['variants'] != null && json['variants'] is List) {
      variantsList =
          (json['variants'] as List)
              .map((v) => ProductVariant.fromJson(v))
              .toList();
    }

    // 2. معالجة التقييمات (Reviews) ✅
    List<ProductReview> reviewsList = [];
    if (json['reviews'] != null && json['reviews'] is List) {
      reviewsList =
          (json['reviews'] as List)
              .map((r) => ProductReview.fromJson(r))
              .toList();
    }

    // 3. تحديد الصورة والسعر الافتراضي
    String displayImage = '';
    double displayPrice =
        double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;

    if (json['image_url'] != null) {
      displayImage = json['image_url'].toString();
    } else if (variantsList.isNotEmpty &&
        variantsList.first.images.isNotEmpty) {
      displayImage = variantsList.first.images.first;
    }

    return ProductDetailsModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      merchantId:
          json['merchant_id']?.toString() ??
          json['merchantId']?.toString() ??
          '0',
      merchantName: json['merchantName'] ?? json['merchant_name'] ?? 'Unknown',
      isDropshipping:
          json['is_dropshipping'] == true || json['is_dropshipping'] == 1,
      variants: variantsList,
      reviews: reviewsList, // ✅ ربط القائمة
      imageUrl: displayImage,
      price: displayPrice,
      avgRating: double.tryParse(json['rating']?.toString() ?? 
                               json['average_rating']?.toString() ?? 
                               json['avg_rating']?.toString() ?? ''),
    );
  }

  // تحويل لنموذج ProductModel (للسلة والمفضلة)
  ProductModel toProductModel() {
    return ProductModel(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      price: price,
      rating: _calculateAverageRating(), // ✅ حساب التقييم
      reviewCount: reviews.length, // ✅ عدد التقييمات
      merchantId: merchantId,
      merchantName: merchantName,
      isNew: false,
      status: 'active',
      stock: 100,
      variants: variants,
      isDropshipping: isDropshipping,
    );
  }

  // دالة مساعدة لحساب متوسط التقييم
  double _calculateAverageRating() {
    if (reviews.isEmpty) return 0.0;
    double total = reviews.fold(0, (sum, item) => sum + item.rating);
    return total / reviews.length;
  }
}

// ✅ كلاس التقييمات (ProductReview)
class ProductReview {
  final int id;
  final double rating;
  final String comment;
  final String userName;
  final String createdAt;

  ProductReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      comment: json['comment'] ?? '',
      // التعامل مع احتمالات مختلفة لاسم المستخدم حسب الباك إند
      userName:
          json['user_name'] ??
          json['userName'] ??
          json['user']?['name'] ??
          'مستخدم',
      createdAt: json['created_at'] ?? '',
    );
  }
}
