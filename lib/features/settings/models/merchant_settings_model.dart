class SettingsData {
  String storeName;
  String storeDescription;
  String? storeBannerUrl;
  String? profilePictureUrl;
  SocialLinks socialLinks;
  NotificationSettings notifications;
  PrivacySettings privacy;

  SettingsData({
    required this.storeName,
    required this.storeDescription,
    this.storeBannerUrl,
    this.profilePictureUrl,
    required this.socialLinks,
    required this.notifications,
    required this.privacy,
  });

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      storeName: json['store_name'] ?? '',
      storeDescription: json['store_description'] ?? '',
      storeBannerUrl: json['store_banner_url'],
      profilePictureUrl: json['profile_picture_url'],
      socialLinks: SocialLinks.fromJson(json['social_links'] ?? {}),
      notifications: NotificationSettings.fromJson(json['notifications'] ?? {}),
      privacy: PrivacySettings.fromJson(json['privacy'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_name': storeName,
      'store_description': storeDescription,
      'store_banner_url': storeBannerUrl,
      'profile_picture_url': profilePictureUrl,
      'social_links': socialLinks.toJson(),
      'notifications': notifications.toJson(),
      'privacy': privacy.toJson(),
    };
  }
}

class SocialLinks {
  String? instagram;
  String? twitter;
  String? facebook;

  SocialLinks({this.instagram, this.twitter, this.facebook});

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      instagram: json['instagram'],
      twitter: json['twitter'],
      facebook: json['facebook'],
    );
  }

  Map<String, dynamic> toJson() => {
    'instagram': instagram,
    'twitter': twitter,
    'facebook': facebook,
  };
}

class NotificationSettings {
  bool email;
  bool sms;
  bool push;

  NotificationSettings({this.email = false, this.sms = false, this.push = false});

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      email: json['email'] == true || json['email'] == 1,
      sms: json['sms'] == true || json['sms'] == 1,
      push: json['push'] == true || json['push'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {'email': email, 'sms': sms, 'push': push};
}

class PrivacySettings {
  bool showEmail;
  bool showPhone;

  PrivacySettings({this.showEmail = false, this.showPhone = false});

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      showEmail: json['show_email'] == true || json['show_email'] == 1,
      showPhone: json['show_phone'] == true || json['show_phone'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {'show_email': showEmail, 'show_phone': showPhone};
}

class SubscriptionData {
  final int id;
  final String status;
  final String startDate;
  final String endDate;
  final String planName;
  final double price;

  SubscriptionData({
    required this.id,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.planName,
    required this.price,
  });

  factory SubscriptionData.fromJson(Map<String, dynamic> json) {
    return SubscriptionData(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'inactive',
      startDate: json['start_date'] ?? json['startDate'] ?? '',
      endDate: json['end_date'] ?? json['endDate'] ?? '',
      planName: json['plan']?['name'] ?? json['plan_name'] ?? 'Unknown',
      price: double.tryParse((json['plan']?['price'] ?? json['price'] ?? '0').toString()) ?? 0.0,
    );
  }
}