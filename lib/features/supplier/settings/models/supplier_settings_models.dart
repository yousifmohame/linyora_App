class SettingsData {
  String storeName;
  String storeDescription;
  String? storeBannerUrl;
  SocialLinks socialLinks;
  NotificationsSettings notifications;
  PrivacySettings privacy;

  SettingsData({
    required this.storeName,
    required this.storeDescription,
    this.storeBannerUrl,
    required this.socialLinks,
    required this.notifications,
    required this.privacy,
  });

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      storeName: json['store_name'] ?? '',
      storeDescription: json['store_description'] ?? '',
      storeBannerUrl: json['store_banner_url'],
      socialLinks: SocialLinks.fromJson(json['social_links'] ?? {}),
      notifications: NotificationsSettings.fromJson(json['notifications'] ?? {}),
      privacy: PrivacySettings.fromJson(json['privacy'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'store_name': storeName,
    'store_description': storeDescription,
    'store_banner_url': storeBannerUrl,
    'social_links': socialLinks.toJson(),
    'notifications': notifications.toJson(),
    'privacy': privacy.toJson(),
  };
}

class SocialLinks {
  String instagram;
  String twitter;
  String facebook;

  SocialLinks({this.instagram = '', this.twitter = '', this.facebook = ''});

  factory SocialLinks.fromJson(Map<String, dynamic> json) => SocialLinks(
    instagram: json['instagram'] ?? '',
    twitter: json['twitter'] ?? '',
    facebook: json['facebook'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'instagram': instagram,
    'twitter': twitter,
    'facebook': facebook,
  };
}

class NotificationsSettings {
  bool email;
  bool sms;
  bool push;

  NotificationsSettings({this.email = false, this.sms = false, this.push = false});

  factory NotificationsSettings.fromJson(Map<String, dynamic> json) => NotificationsSettings(
    email: json['email'] ?? false,
    sms: json['sms'] ?? false,
    push: json['push'] ?? false,
  );

  Map<String, dynamic> toJson() => {'email': email, 'sms': sms, 'push': push};
}

class PrivacySettings {
  bool showEmail;
  bool showPhone;

  PrivacySettings({this.showEmail = false, this.showPhone = false});

  factory PrivacySettings.fromJson(Map<String, dynamic> json) => PrivacySettings(
    showEmail: json['show_email'] ?? false,
    showPhone: json['show_phone'] ?? false,
  );

  Map<String, dynamic> toJson() => {'show_email': showEmail, 'show_phone': showPhone};
}