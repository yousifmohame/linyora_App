import 'product_model.dart';
import 'reel_model.dart';

// --- موديل التاجر (Merchant) ---
class PublicMerchantProfile {
  final int id;
  final String name;
  final String storeName;
  final String? profilePictureUrl;
  final String? coverUrl;
  final String? bio;
  final String? location;
  final String? joinedDate;
  final double rating;
  final int reviewsCount;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int totalSales;
  bool isFollowedByMe; // قابل للتغيير عند الضغط
  final List<ProductModel> products;

  PublicMerchantProfile({
    required this.id,
    required this.name,
    required this.storeName,
    this.profilePictureUrl,
    this.coverUrl,
    this.bio,
    this.location,
    this.joinedDate,
    required this.rating,
    required this.reviewsCount,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.totalSales,
    required this.isFollowedByMe,
    required this.products,
  });

  factory PublicMerchantProfile.fromJson(Map<String, dynamic> json) {
    return PublicMerchantProfile(
      id: json['id'],
      name: json['name'] ?? '',
      storeName: json['store_name'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
      coverUrl: json['cover_url'], // store_banner_url as alias
      bio: json['bio'],
      location: json['location'],
      joinedDate: json['joined_date'],
      rating: double.parse((json['rating'] ?? 0).toString()),
      reviewsCount: json['reviews_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      totalSales: json['total_sales'] ?? 0,
      isFollowedByMe: json['isFollowedByMe'] == true || json['isFollowedByMe'] == 1,
      products: (json['products'] as List?)
              ?.map((i) => ProductModel.fromJson(i))
              .toList() ??
          [],
    );
  }
}

// --- موديل المودل (Model) ---
class PublicModelProfile {
  final UserProfile profile;
  final List<ReelModel> reels;
  final List<ServicePackage> services;
  final List<Offer> offers;

  PublicModelProfile({
    required this.profile,
    required this.reels,
    required this.services,
    required this.offers,
  });

  factory PublicModelProfile.fromJson(Map<String, dynamic> json) {
    return PublicModelProfile(
      profile: UserProfile.fromJson(json['profile']),
      reels: (json['reels'] as List?)?.map((i) => ReelModel.fromJson(i)).toList() ?? [],
      services: (json['services'] as List?)?.map((i) => ServicePackage.fromJson(i)).toList() ?? [],
      offers: (json['offers'] as List?)?.map((i) => Offer.fromJson(i)).toList() ?? [],
    );
  }
}

class UserProfile {
  final int id;
  final String name;
  final String? profilePictureUrl;
  final String? coverUrl;
  final String? bio;
  final String roleName;
  final bool isVerified;
  bool isFollowedByMe;
  final ProfileStats stats;
  final SocialLinks socialLinks;
  final List<String> portfolio;

  UserProfile({
    required this.id,
    required this.name,
    this.profilePictureUrl,
    this.coverUrl,
    this.bio,
    required this.roleName,
    required this.isVerified,
    required this.isFollowedByMe,
    required this.stats,
    required this.socialLinks,
    required this.portfolio,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      profilePictureUrl: json['profile_picture_url'],
      coverUrl: json['cover_url'] ?? json['store_banner_url'],
      bio: json['bio'],
      roleName: json['role_name'] ?? 'Influencer',
      isVerified: json['is_verified'] == true,
      isFollowedByMe: json['isFollowedByMe'] == true,
      stats: ProfileStats.fromJson(json['stats'] ?? {}),
      socialLinks: SocialLinks.fromJson(json['social_links'] ?? {}),
      portfolio: (json['portfolio'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class ProfileStats {
  final int followers;
  final int reelsCount;
  final int inAppFollowers;

  ProfileStats({this.followers = 0, this.reelsCount = 0, this.inAppFollowers = 0});

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      followers: int.tryParse(json['followers'].toString()) ?? 0,
      reelsCount: int.tryParse(json['reelsCount'].toString()) ?? 0,
      inAppFollowers: int.tryParse(json['inAppFollowers'].toString()) ?? 0,
    );
  }
}

class SocialLinks {
  final String? instagram;
  final String? twitter;
  final String? youtube;
  final String? tiktok;
  final String? snapchat;
  final String? facebook;

  SocialLinks({this.instagram, this.twitter, this.youtube, this.tiktok, this.snapchat, this.facebook});

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      instagram: json['instagram'],
      twitter: json['twitter'],
      youtube: json['youtube'],
      tiktok: json['tiktok'],
      snapchat: json['snapchat'],
      facebook: json['facebook'],
    );
  }
}

class ServicePackage {
  final int id;
  final String title;
  final String description;
  final double startingPrice;

  ServicePackage({required this.id, required this.title, required this.description, required this.startingPrice});

  factory ServicePackage.fromJson(Map<String, dynamic> json) {
    return ServicePackage(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startingPrice: double.parse(json['starting_price'].toString()),
    );
  }
}

class Offer {
  final int id;
  final String title;
  final String description;
  final double price;
  final String type;

  Offer({required this.id, required this.title, required this.description, required this.price, required this.type});

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      type: json['type'],
    );
  }
}