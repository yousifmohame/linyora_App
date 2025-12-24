import '../core/utils/image_helper.dart';

class BannerModel {
  final int id;
  final String title;
  final String subtitle;
  final String imageUrl; // قد يكون رابط فيديو أو صورة
  final String buttonText;
  final String link;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.buttonText,
    required this.link,
  });

  // 👇 خاصية ذكية لمعرفة هل هو فيديو أم لا
  bool get isVideo {
    return imageUrl.toLowerCase().contains('.mp4') ||
        imageUrl.toLowerCase().contains('.mov') ||
        imageUrl.toLowerCase().contains('video');
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      // استخدام ImageHelper الذي أنشأناه سابقاً لضمان صحة الرابط
      imageUrl: ImageHelper.getValidUrl(json['image_url']),
      buttonText: json['button_text'] ?? '',
      link: json['link_url'] ?? '',
    );
  }
}
