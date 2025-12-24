import '../core/utils/image_helper.dart';

class StoryFeedItem {
  final int id; // إما user_id أو section_id
  final String title; // userName أو title
  final String imageUrl; // userAvatar أو cover_image
  final bool isAdminSection; // لتحديد الشكل (دائري أو مربع)
  final bool allViewed; // لتحديد لون الإطار

  StoryFeedItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.isAdminSection,
    required this.allViewed,
  });

  factory StoryFeedItem.fromJson(Map<String, dynamic> json) {
    // حسب ملف storyController.js
    // للمستخدم: userName, userAvatar
    // للقسم: title, cover_image
    bool isAdmin = json['isAdminSection'] == 1 || json['isAdminSection'] == true;
    
    return StoryFeedItem(
      id: json['id'],
      title: isAdmin ? (json['title'] ?? '') : (json['userName'] ?? 'مستخدم'),
      imageUrl: ImageHelper.getValidUrl(isAdmin ? json['cover_image'] : json['userAvatar']),
      isAdminSection: isAdmin,
      allViewed: json['allViewed'] == true || json['allViewed'] == 1,
    );
  }
}