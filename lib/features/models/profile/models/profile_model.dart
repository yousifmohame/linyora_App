class ProfileData {
  String name;
  String email;
  String bio;
  String? profilePictureUrl;
  String? storeBannerUrl;
  List<String> portfolio;
  SocialLinks socialLinks;
  Stats stats;

  // ✅ تمت الإضافة: عدد متابعي المنصة (الداخلي)
  int followersCount;

  ProfileData({
    required this.name,
    required this.email,
    required this.bio,
    this.profilePictureUrl,
    this.storeBannerUrl,
    required this.portfolio,
    required this.socialLinks,
    required this.stats,
    // ✅ قيمة افتراضية
    this.followersCount = 0,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
      storeBannerUrl: json['store_banner_url'],
      portfolio:
          (json['portfolio'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      socialLinks: SocialLinks.fromJson(json['social_links'] ?? {}),
      stats: Stats.fromJson(json['stats'] ?? {}),

      // ✅ قراءة العدد بأمان (سواء كان int أو String أو غير موجود)
      followersCount:
          json['followers_count'] is int
              ? json['followers_count']
              : int.tryParse(json['followers_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'bio': bio,
    'profile_picture_url': profilePictureUrl,
    'store_banner_url': storeBannerUrl,
    'portfolio': portfolio,
    'social_links': socialLinks.toJson(),
    'stats': stats.toJson(),
    // ✅ إضافته للـ JSON (اختياري حسب حاجتك لإرساله)
    'followers_count': followersCount,
  };
}

// الكلاسات الأخرى تبقى كما هي بدون تغيير
class SocialLinks {
  String instagram;
  String twitter;
  String facebook;
  String tiktok;
  String snapchat;
  String whatsapp;

  SocialLinks({
    this.instagram = '',
    this.twitter = '',
    this.facebook = '',
    this.tiktok = '',
    this.snapchat = '',
    this.whatsapp = '',
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      instagram: json['instagram'] ?? '',
      twitter: json['twitter'] ?? '',
      facebook: json['facebook'] ?? '',
      tiktok: json['tiktok'] ?? '',
      snapchat: json['snapchat'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'instagram': instagram,
    'twitter': twitter,
    'facebook': facebook,
    'tiktok': tiktok,
    'snapchat': snapchat,
    'whatsapp': whatsapp,
  };
}

class Stats {
  String followers;
  String engagement;

  Stats({this.followers = '', this.engagement = ''});

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      followers: json['followers'] ?? '',
      engagement: json['engagement'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'followers': followers,
    'engagement': engagement,
  };
}
