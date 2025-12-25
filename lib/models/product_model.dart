import '../core/utils/image_helper.dart';

class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final double? compare_at_price;
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
    // تهيئة المتغيرات
    double price = 0.0;
    double? compare_at_price;
    String imageUrl = '';

    // ---------------------------------------------------------
    // السيناريو الأول: البيانات قادمة من تفاصيل المنتج (يوجد Variants)
    // ---------------------------------------------------------
    if (json['variants'] != null && (json['variants'] as List).isNotEmpty) {
      final firstVariant = json['variants'][0];
      price = double.tryParse(firstVariant['price'].toString()) ?? 0.0;
      compare_at_price = double.tryParse(firstVariant['compare_at_price'].toString());

      if (firstVariant['images'] != null) {
        var imgs = firstVariant['images'];
        if (imgs is List && imgs.isNotEmpty) {
          imageUrl = imgs[0].toString();
        } else if (imgs is String) {
             // أحياناً يتم تخزين JSON كـ String في قاعدة البيانات
             imageUrl = imgs; 
        }
      }
    } 
    
    // ---------------------------------------------------------
    // السيناريو الثاني: البيانات قادمة من البحث (Flat Data)
    // أو فشل استخراج البيانات من Variants
    // ---------------------------------------------------------
    
    // 1. معالجة السعر (إذا لم يتم تعيينه من الـ Variants)
    if (price == 0.0 && json['price'] != null) {
      price = double.tryParse(json['price'].toString()) ?? 0.0;
    }

    // 2. معالجة الصورة (الأولوية لـ image_url القادمة من البحث)
    if (imageUrl.isEmpty) {
      if (json['image_url'] != null) {
        // هذا هو المفتاح الذي يرسله كود البحث (MySQL)
        imageUrl = json['image_url'].toString();
      } else if (json['image'] != null) {
        // احتياطي
        imageUrl = json['image'].toString();
      }
    }

    // 3. معالجة اسم التاجر أو العلامة التجارية
    // البحث يرجع 'brand' بينما التفاصيل قد ترجع 'merchantName'
    String merchant = '';
    if (json['merchantName'] != null) {
      merchant = json['merchantName'];
    } else if (json['brand'] != null) {
      merchant = json['brand'];
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
      price: price,
      compare_at_price: compare_at_price,
      // نستخدم ImageHelper لضمان أن الرابط صالح (يضيف الدومين إذا كان ناقصاً)
      imageUrl: ImageHelper.getValidUrl(imageUrl),
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      reviewCount: int.tryParse(json['reviewCount'].toString()) ?? 0,
      merchantName: merchant,
      isNew: isNewProduct,
    );
  }
}