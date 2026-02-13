import 'dart:convert'; // ✅ ضروري لفك تشفير النصوص

class ModelStats {
  final String followers;
  final String engagement;
  final int completedProjects;
  final double rating;

  ModelStats({
    this.followers = '0',
    this.engagement = '0%',
    this.completedProjects = 0,
    this.rating = 0.0,
  });

  factory ModelStats.fromJson(Map<String, dynamic> json) {
    return ModelStats(
      followers: json['followers']?.toString() ?? '0',
      engagement: json['engagement']?.toString() ?? '0%',
      completedProjects:
          int.tryParse(json['completed_projects']?.toString() ?? '0') ?? 0,
      rating: double.tryParse(json['engagement']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}

class SocialLinks {
  final String? instagram;
  final String? twitter;
  final String? facebook;
  final String? tiktok;   // ✅ تمت الإضافة
  final String? snapchat;

  SocialLinks({this.instagram, this.twitter, this.facebook, this.tiktok, this.snapchat});

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      instagram: json['instagram'],
      twitter: json['twitter'],
      facebook: json['facebook'],
      tiktok: json['tiktok']?.toString(),
      snapchat: json['snapchat'],
    );
  }
}

class BrowsedModel {
  final int id;
  final String name;
  final int roleId;
  final String? profilePictureUrl;
  final String bio;
  final ModelStats stats;
  final String? location;
  final List<String> categories;
  final SocialLinks? socialLinks;
  final bool isVerified;
  final bool isFeatured;

  BrowsedModel({
    required this.id,
    required this.name,
    required this.roleId,
    this.profilePictureUrl,
    this.bio = '',
    required this.stats,
    this.location,
    required this.categories,
    this.socialLinks,
    this.isVerified = false,
    this.isFeatured = false,
  });

  factory BrowsedModel.fromJson(Map<String, dynamic> json) {
    // 🛠️ حل المشكلة: معالجة stats سواء جاءت كنص أو كائن
    var statsData = json['stats'];
    if (statsData is String) {
      try {
        statsData = jsonDecode(statsData);
      } catch (e) {
        statsData = {};
      }
    }

    // 🛠️ حل المشكلة: معالجة social_links سواء جاءت كنص أو كائن
    var socialData = json['social_links'];
    if (socialData is String) {
      try {
        socialData = jsonDecode(socialData);
      } catch (e) {
        socialData = null;
      }
    }

    // 🛠️ حل المشكلة: معالجة categories
    List<String> parsedCategories = [];
    if (json['categories'] != null) {
      if (json['categories'] is String) {
        // إذا جاءت كنص مثل "fashion, beauty"
        try {
          // محاولة فكها كـ JSON Array
          parsedCategories = List<String>.from(jsonDecode(json['categories']));
        } catch (e) {
          // إذا فشل، ربما هي مفصولة بفواصل
          parsedCategories =
              json['categories']
                  .toString()
                  .split(',')
                  .map((e) => e.trim())
                  .toList();
        }
      } else if (json['categories'] is List) {
        // إذا جاءت كمصفوفة طبيعية
        parsedCategories = List<String>.from(json['categories']);
      }
    }

    return BrowsedModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      roleId:
          json['role_id'] is int
              ? json['role_id']
              : int.tryParse(json['role_id']?.toString() ?? '3') ?? 3,
      profilePictureUrl: json['profile_picture_url'],
      bio: json['bio'] ?? '',

      // تمرير البيانات المعالجة
      stats:
          statsData != null
              ? ModelStats.fromJson(Map<String, dynamic>.from(statsData))
              : ModelStats(),

      location: json['location'],

      categories: parsedCategories,

      // تمرير البيانات المعالجة
      socialLinks:
          socialData != null
              ? SocialLinks.fromJson(Map<String, dynamic>.from(socialData))
              : null,

      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
    );
  }
}
