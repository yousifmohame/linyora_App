class ProductDetailsModel {
  final int id;
  final String name;
  final String description;
  final int merchantId;
  final String merchantName;
  final bool isDropshipping;
  final List<ProductVariant> variants;
  final List<ProductReview> reviews;

  ProductDetailsModel({
    required this.id,
    required this.name,
    required this.description,
    required this.merchantId,
    required this.merchantName,
    required this.isDropshipping,
    required this.variants,
    required this.reviews,
  });

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailsModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      merchantId: json['merchant_id'] ?? json['merchantId'] ?? 0,
      merchantName: json['merchantName'] ?? '',
      isDropshipping: json['is_dropshipping'] == true,
      variants: (json['variants'] as List?)
              ?.map((v) => ProductVariant.fromJson(v))
              .toList() ??
          [],
      reviews: (json['reviews'] as List?)
              ?.map((r) => ProductReview.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class ProductVariant {
  final int id;
  final double price;
  final double? compareAtPrice;
  final int stockQuantity;
  final String color;
  final List<String> images;

  ProductVariant({
    required this.id,
    required this.price,
    this.compareAtPrice,
    required this.stockQuantity,
    required this.color,
    required this.images,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    // معالجة الصور التي قد تأتي كنص JSON أو قائمة
    List<String> parsedImages = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        parsedImages = List<String>.from(json['images']);
      } else if (json['images'] is String) {
        // في حال كانت نصاً وتخلصنا من الأقواس المربعة يدوياً (أو تركناها كما هي حسب الباك اند)
        // الأفضل تركها فارغة هنا لأن الباك اند يرسلها parsed حسب الكود الخاص بك
      }
    }

    return ProductVariant(
      id: json['id'],
      price: double.parse(json['price'].toString()),
      compareAtPrice: json['compare_at_price'] != null
          ? double.parse(json['compare_at_price'].toString())
          : null,
      stockQuantity: json['stock_quantity'] ?? 0,
      color: json['color'] ?? '',
      images: parsedImages,
    );
  }
}

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
      id: json['id'],
      rating: double.parse(json['rating'].toString()),
      comment: json['comment'] ?? '',
      userName: json['userName'] ?? 'مستخدم',
      createdAt: json['created_at'] ?? '',
    );
  }
}