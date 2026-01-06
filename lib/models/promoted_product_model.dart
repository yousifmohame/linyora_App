import 'package:flutter/material.dart';

class PromotedProductModel {
  final int id;
  final String name;
  final String brand;
  final double price;
  final double? compareAtPrice; // السعر قبل الخصم
  final String image;
  final String promotionTierName; // اسم الترويج (مثلاً "Hot", "Best Seller")
  final String badgeColor; // لون الشارة من قاعدة البيانات (Hex Code)

  PromotedProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.compareAtPrice,
    required this.image,
    required this.promotionTierName,
    required this.badgeColor,
  });

  factory PromotedProductModel.fromJson(Map<String, dynamic> json) {
    return PromotedProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      // تحويل الأرقام بأمان
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      compareAtPrice: json['compare_at_price'] != null 
          ? double.tryParse(json['compare_at_price'].toString()) 
          : null,
      image: json['image'] ?? '', // الباك إند يرسل صورة واحدة كـ String
      promotionTierName: json['promotion_tier_name'] ?? '',
      badgeColor: json['badge_color'] ?? '#000000', // لون افتراضي أسود
    );
  }

  // دالة مساعدة لتحويل كود اللون (#FF0000) إلى Color في Flutter
  Color get parsedBadgeColor {
    try {
      String hex = badgeColor.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex'; // إضافة الشفافية الكاملة
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.black; // لون احتياطي
    }
  }
}