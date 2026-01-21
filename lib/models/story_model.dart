import '../core/utils/image_helper.dart';

enum MediaType { image, video, text }

class StoryModel {
  final int id;
  final String? mediaUrl;
  final MediaType mediaType;
  final String? textContent;
  final String? backgroundColor;

  // بيانات المنتج
  final int? productId;
  final String? productName;
  final double? productPrice;
  final String? productImage; // ✅ ضروري جداً لقصص المنتجات

  bool isViewed;

  StoryModel({
    required this.id,
    this.mediaUrl,
    required this.mediaType,
    this.textContent,
    this.backgroundColor,
    this.productId,
    this.productName,
    this.productPrice,
    this.productImage,
    this.isViewed = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    // 1. معالجة رابط الميديا المرفقة
    String rawUrl = ImageHelper.getValidUrl(json['media_url']);

    // 2. معالجة رابط صورة المنتج (مهم جداً)
    String? rawProductImage;
    if (json['product_image'] != null) {
      rawProductImage = ImageHelper.getValidUrl(json['product_image']);
    }

    // 3. فحص هل الميديا المرفقة هي الصورة الافتراضية؟
    bool isPlaceholder = rawUrl == "https://placehold.co/400" || rawUrl.isEmpty;

    // 4. تحديد النوع بذكاء
    MediaType type = MediaType.image; // الافتراضي
    String backendType = json['type'] ?? 'image';

    if (backendType == 'video' || rawUrl.endsWith('.mp4')) {
      type = MediaType.video;
    } else if (backendType == 'text') {
      // 🔥 تصحيح هام:
      // إذا كان النوع "نص" ولكن يوجد منتج (Product ID)، نعتبرها "صورة"
      // لكي يقوم الـ UI بعرض صورة المنتج بدلاً من مجرد خلفية ملونة
      if (json['product_id'] != null) {
        type = MediaType.image;
      } else {
        type = MediaType.text;
      }
    } else if (isPlaceholder && json['product_id'] == null) {
      // إذا كانت الصورة افتراضية ولا يوجد منتج، نتحول إلى نص
      type = MediaType.text;
    }

    return StoryModel(
      id: int.tryParse(json['id'].toString()) ?? 0,

      // ✅ إذا كان placeholder، نجعله null لكي يستخدم الـ UI صورة المنتج بدلاً منه
      mediaUrl: isPlaceholder ? null : rawUrl,

      mediaType: type,
      textContent: json['text_content'],
      backgroundColor: json['background_color'],

      // بيانات المنتج
      productId: int.tryParse(json['product_id']?.toString() ?? ''),
      productName: json['product_name'],
      productPrice: double.tryParse(json['product_price']?.toString() ?? '0'),
      productImage: rawProductImage, // ✅ تخزين صورة المنتج

      isViewed: json['isViewed'] == true || json['isViewed'] == 1,
    );
  }
}
