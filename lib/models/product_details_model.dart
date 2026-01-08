

import 'package:linyora_project/core/utils/image_helper.dart';

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
  final int? id;
  final String color;
  final double price;
  final double? compareAtPrice;
  final int stockQuantity;
  final String? sku;
  final List<String> images;

  ProductVariant({
    this.id,
    required this.color,
    required this.price,
    this.compareAtPrice,
    required this.stockQuantity,
    this.sku,
    required this.images,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    // ✅ إصلاح آمن للصور: التأكد من أنها قائمة
    List<String> parsedImages = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        parsedImages =
            (json['images'] as List)
                .map((e) => ImageHelper.getValidUrl(e.toString()))
                .toList();
      } else if (json['images'] is String) {
        // في بعض الأحيان قد تأتي كسلسلة نصية واحدة
        parsedImages = [ImageHelper.getValidUrl(json['images'])];
      }
    }

    return ProductVariant(
      id: int.tryParse(json['id'].toString()),
      color: json['color'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      compareAtPrice:
          json['compare_at_price'] != null
              ? double.tryParse(json['compare_at_price'].toString())
              : null,
      stockQuantity: int.tryParse(json['stock_quantity'].toString()) ?? 0,
      sku: json['sku'],
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