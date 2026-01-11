import '../core/utils/image_helper.dart';

enum MediaType { image, video, text }

class StoryModel {
  final int id;
  final String? mediaUrl; // نتركه يقبل null داخلياً
  final MediaType mediaType;
  final String? textContent;
  final String? backgroundColor;
  final int? productId;
  final String? productName;
  final double? productPrice;
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
    this.isViewed = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    // 1. نجلب الرابط من ImageHelper كما هو (لن نغيره)
    String rawUrl = ImageHelper.getValidUrl(json['media_url']);
    
    // 2. الفحص الذكي: هل هذا الرابط هو الصورة الافتراضية؟
    // هذا الرابط هو الذي وضعته أنت في ImageHelper
    bool isPlaceholder = rawUrl == "https://placehold.co/400";

    // 3. تحديد النوع
    MediaType type = MediaType.image; // الافتراضي

    // إذا جاء من الباك إند أنه نص، أو إذا اكتشفنا أنه الرابط الافتراضي (يعني لا توجد صورة)
    if (json['type'] == 'text' || isPlaceholder) {
      type = MediaType.text;
    } else if (json['type'] == 'video' || rawUrl.endsWith('.mp4')) {
      type = MediaType.video;
    }

    return StoryModel(
      id: json['id'],
      // ✅ الحيلة هنا: إذا كان placeholder، نجعل mediaUrl يساوي null داخل المودل فقط
      // هذا سيمنع story_view من محاولة تحميل الصورة الافتراضية
      mediaUrl: isPlaceholder ? null : rawUrl, 
      mediaType: type,
      textContent: json['text_content'],
      backgroundColor: json['background_color'],
      productId: json['product_id'],
      productName: json['product_name'],
      productPrice: double.tryParse(json['product_price']?.toString() ?? '0'),
      isViewed: json['isViewed'] == true || json['isViewed'] == 1,
    );
  }
}