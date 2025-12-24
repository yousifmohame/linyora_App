import '../core/utils/image_helper.dart';

enum MediaType { image, video }

class StoryModel {
  final int id;
  final String mediaUrl;
  final MediaType mediaType;
  final String? textContent; // نص القصة (إن وجد)
  final int? productId; // إذا كانت القصة مرتبطة بمنتج
  final bool isViewed;

  StoryModel({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    this.textContent,
    this.productId,
    this.isViewed = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    String url = ImageHelper.getValidUrl(json['media_url']);
    // تحديد النوع بناءً على الحقل 'type' القادم من قاعدة البيانات أو امتداد الملف
    bool isVideo = json['type'] == 'video' || url.endsWith('.mp4');

    return StoryModel(
      id: json['id'],
      mediaUrl: url,
      mediaType: isVideo ? MediaType.video : MediaType.image,
      textContent: json['text_content'],
      productId: json['product_id'],
      isViewed: json['isViewed'] == true || json['isViewed'] == 1,
    );
  }
}