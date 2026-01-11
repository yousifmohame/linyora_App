import 'browsed_model.dart'; // استيراد المودل السابق لاستخدام Stats و SocialLinks

class Offer {
  final int id;
  final String title;
  final String type;
  final String description;
  final double price;

  Offer({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.price,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'],
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}

class ServicePackage {
  final int id;
  final String title;
  final String description;
  final List<PackageTier> tiers;

  ServicePackage({
    required this.id,
    required this.title,
    required this.description,
    required this.tiers,
  });

  factory ServicePackage.fromJson(Map<String, dynamic> json) {
    var tiersList = <PackageTier>[];

    // محاولة قراءة التيرز بأسماء مفاتيح مختلفة لتجنب الأخطاء
    if (json['tiers'] != null) {
      json['tiers'].forEach((v) {
        tiersList.add(PackageTier.fromJson(v));
      });
    } else if (json['package_tiers'] != null) {
      json['package_tiers'].forEach((v) {
        tiersList.add(PackageTier.fromJson(v));
      });
    }

    return ServicePackage(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? json['name'] ?? 'باقة بلا عنوان',
      description: json['description'] ?? '',
      tiers: tiersList,
    );
  }
}

class PackageTier {
  final int id;
  final String tierName;
  final double price;
  final int deliveryDays;
  final int revisions;
  final List<String> features;

  PackageTier({
    required this.id,
    required this.tierName,
    required this.price,
    required this.deliveryDays,
    required this.revisions,
    required this.features,
  });

  factory PackageTier.fromJson(Map<String, dynamic> json) {
    // معالجة المميزات: سواء جاءت كقائمة أو كنص
    List<String> parsedFeatures = [];
    if (json['features'] != null) {
      if (json['features'] is List) {
        parsedFeatures = List<String>.from(
          json['features'].map((e) => e.toString()),
        );
      } else if (json['features'] is String) {
        // إذا جاءت كنص مفصول بفواصل
        parsedFeatures = (json['features'] as String).split(',');
      }
    }

    return PackageTier(
      id: int.tryParse(json['id'].toString()) ?? 0,
      // تجربة أكثر من مفتاح للاسم
      tierName:
          json['tier_name'] ??
          json['name'] ??
          json['title'] ??
          'مستوى غير محدد',
      // تحويل السعر بأمان حتى لو جاء كنص
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      deliveryDays: int.tryParse(json['delivery_days'].toString()) ?? 0,
      revisions: int.tryParse(json['revisions'].toString()) ?? 0,
      features: parsedFeatures,
    );
  }
}

class MerchantProduct {
  final int id;
  final String name;
  final String? imageUrl;
  final String? category;

  MerchantProduct({
    required this.id,
    required this.name,
    this.imageUrl,
    this.category,
  });

  factory MerchantProduct.fromJson(Map<String, dynamic> json) {
    return MerchantProduct(
      id: json['id'],
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
      category: json['category'],
    );
  }
}

class ModelFullProfile extends BrowsedModel {
  final List<String> portfolio;
  final int experienceYears;
  final List<String> languages;
  final int completedCampaigns;

  // Stats details specific to profile page
  final String avgResponseTime;
  final String completionRate;

  ModelFullProfile({
    required int id,
    required String name,
    required int roleId,
    String? profilePictureUrl,
    String bio = '',
    required ModelStats stats,
    String? location,
    required List<String> categories,
    SocialLinks? socialLinks,
    bool isVerified = false,
    bool isFeatured = false,
    this.portfolio = const [],
    this.experienceYears = 0,
    this.languages = const [],
    this.completedCampaigns = 0,
    this.avgResponseTime = 'N/A',
    this.completionRate = 'N/A',
  }) : super(
         id: id,
         name: name,
         roleId: roleId,
         profilePictureUrl: profilePictureUrl,
         bio: bio,
         stats: stats,
         location: location,
         categories: categories,
         socialLinks: socialLinks,
         isVerified: isVerified,
         isFeatured: isFeatured,
       );

  factory ModelFullProfile.fromJson(Map<String, dynamic> json) {
    // Reuse the logic from BrowsedModel using a factory or manual parsing
    // Here we manually parse extending fields
    final base = BrowsedModel.fromJson(json);

    var statsJson = json['stats'] ?? {};

    return ModelFullProfile(
      id: base.id,
      name: base.name,
      roleId: base.roleId,
      profilePictureUrl: base.profilePictureUrl,
      bio: base.bio,
      stats: base.stats,
      location: base.location,
      categories: base.categories,
      socialLinks: base.socialLinks,
      isVerified: base.isVerified,
      isFeatured: base.isFeatured,
      portfolio:
          json['portfolio'] != null ? List<String>.from(json['portfolio']) : [],
      experienceYears:
          int.tryParse(json['experience_years']?.toString() ?? '0') ?? 0,
      languages:
          json['languages'] != null ? List<String>.from(json['languages']) : [],
      completedCampaigns:
          int.tryParse(json['completed_campaigns']?.toString() ?? '0') ?? 0,
      avgResponseTime: statsJson['avg_response_time'] ?? 'N/A',
      completionRate: statsJson['completion_rate'] ?? 'N/A',
    );
  }
}
