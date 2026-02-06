import 'package:linyora_project/models/product_model.dart'; // ✅ هام جداً: استيراد المودل العام

class ProductDetailsModel {
  final int id;
  final String name;
  final String description;
  final String merchantId; // يفضل توحيد النوع مع ProductModel (String)
  final String merchantName;
  final bool isDropshipping;
  final List<ProductVariant> variants; // ✅ نستخدم الفارينت المستورد
  final List<ProductReview> reviews;
  final String imageUrl; // نحتاجها للتحويل
  final double price; // نحتاجها للتحويل

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
  });

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    // استخراج المتغيرات باستخدام المودل الموجود في product_model.dart
    List<ProductVariant> variantsList = [];
    if (json['variants'] != null && json['variants'] is List) {
      variantsList = (json['variants'] as List)
          .map((v) => ProductVariant.fromJson(v))
          .toList();
    }

    // تحديد الصورة والسعر الافتراضي للتحويل لاحقاً
    String displayImage = '';
    double displayPrice = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;

    if (json['image_url'] != null) {
      displayImage = json['image_url'].toString();
    } else if (variantsList.isNotEmpty && variantsList.first.images.isNotEmpty) {
      displayImage = variantsList.first.images.first;
    }

    return ProductDetailsModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      // التعامل المرن مع merchant_id سواء جاء رقم أو نص
      merchantId: json['merchant_id']?.toString() ?? json['merchantId']?.toString() ?? '0',
      merchantName: json['merchantName'] ?? json['merchant_name'] ?? 'Unknown',
      isDropshipping: json['is_dropshipping'] == true || json['is_dropshipping'] == 1,
      variants: variantsList,
      reviews: (json['reviews'] as List?)
              ?.map((r) => ProductReview.fromJson(r))
              .toList() ?? [],
      imageUrl: displayImage,
      price: displayPrice,
    );
  }

  // ✅ دالة التحويل: هذه هي "الحلقة المفقودة" لربط صفحة التفاصيل بالسلة
  ProductModel toProductModel() {
    return ProductModel(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      price: price,
      rating: 0.0, // يمكن حسابها من reviews إذا أردت
      reviewCount: reviews.length,
      merchantId: merchantId,
      merchantName: merchantName,
      isNew: false,
      status: 'active',
      stock: 100, // قيمة افتراضية أو احسبها من variants
      variants: variants,
      isDropshipping: isDropshipping,
    );
  }
}

// ✅ كلاس التقييمات (يمكن إبقاؤه هنا لأنه خاص بالتفاصيل)
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
      userName: json['user_name'] ?? json['userName'] ?? 'مستخدم',
      createdAt: json['created_at'] ?? '',
    );
  }
}

// ❌❌❌ لا تقم بإضافة class ProductVariant هنا مرة أخرى! ❌❌❌