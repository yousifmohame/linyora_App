import '../core/utils/image_helper.dart';

class TopUserModel {
  final int id;
  final String name;
  final String storeName; // للتاجرات
  final String imageUrl;
  final double rating;
  final int followers;
  bool isFollowed; // قابل للتغيير عند الضغط

  TopUserModel({
    required this.id,
    required this.name,
    required this.storeName,
    required this.imageUrl,
    required this.rating,
    required this.followers,
    required this.isFollowed,
  });

  factory TopUserModel.fromJson(Map<String, dynamic> json) {
    return TopUserModel(
      id: json['id'],
      name: json['name'] ?? '',
      storeName: json['store_name'] ?? '', // قد يكون فارغاً للمودلز
      imageUrl: ImageHelper.getValidUrl(json['profile_picture_url']),
      // التعامل مع التقييم سواء جاء كرقم أو نص
      rating: double.tryParse(json['rating'].toString()) ?? 5.0,
      followers: int.tryParse(json['followers'].toString()) ?? 0,
      isFollowed: json['isFollowedByMe'] == true || json['isFollowedByMe'] == 1,
    );
  }
  
  // خاصية للحصول على الاسم المناسب للعرض
  String get displayName => storeName.isNotEmpty ? storeName : name;
}