import '../core/utils/image_helper.dart';

class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final double? compare_at_price; // Compare at price
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String merchantName;
  final bool isNew;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.compare_at_price,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.merchantName,
    this.isNew = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. استخراج السعر والصورة من المتغيرات (Variants)
    double price = 0.0;
    double? compare_at_price;
    String imageUrl = '';

    if (json['variants'] != null && (json['variants'] as List).isNotEmpty) {
      final firstVariant = json['variants'][0];
      price = double.tryParse(firstVariant['price'].toString()) ?? 0.0;
      compare_at_price = double.tryParse(firstVariant['compare_at_price'].toString());
      
      // معالجة الصور (قد تكون نص JSON أو مصفوفة)
      if (firstVariant['images'] != null) {
        var imgs = firstVariant['images'];
        if (imgs is String) {
          // TODO: يمكن إضافة parsing هنا إذا لزم الأمر، لكن غالباً الباك إند يرسلها جاهزة
        } else if (imgs is List && imgs.isNotEmpty) {
          imageUrl = imgs[0];
        }
      }
    } else {
      // احتياطي في حال عدم وجود variants (نادر الحدوث)
      price = double.tryParse(json['price'].toString()) ?? 0.0;
    }

    // صورة احتياطية إذا لم نجد صورة
    if (imageUrl.isEmpty && json['image'] != null) {
      imageUrl = json['image'];
    }

    return ProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: price,
      compare_at_price: compare_at_price,
      imageUrl: ImageHelper.getValidUrl(imageUrl),
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      reviewCount: int.tryParse(json['reviewCount'].toString()) ?? 0,
      merchantName: json['merchantName'] ?? '',
      isNew: DateTime.now().difference(DateTime.parse(json['created_at'] ?? DateTime.now().toString())).inDays < 7,
    );
  }
}