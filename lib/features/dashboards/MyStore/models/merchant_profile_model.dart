import 'package:linyora_project/models/product_model.dart';

class MerchantProfileModel {
  final int id;
  final String storeName;
  final String? coverUrl;
  final String? profileUrl;
  final String? bio;
  final double rating;
  final String? location;
  final int followersCount;
  final int totalSales;
  final int activeProductsCount;
  final bool isVerified;
  final bool isDropshipper;
  final List<ProductModel> products;

  MerchantProfileModel({
    required this.id,
    required this.storeName,
    this.coverUrl,
    this.profileUrl,
    this.bio,
    this.rating = 0.0,
    this.location,
    this.followersCount = 0,
    this.totalSales = 0,
    this.activeProductsCount = 0,
    this.isVerified = false,
    this.isDropshipper = false,
    this.products = const [],
  });

  factory MerchantProfileModel.fromJson(Map<String, dynamic> json) {
    var productsList = <ProductModel>[];
    if (json['products'] != null) {
      productsList =
          (json['products'] as List)
              .map((v) => ProductModel.fromJson(v))
              .toList();
    }

    return MerchantProfileModel(
      id: json['id'] ?? 0,
      storeName: json['store_name'] ?? json['name'] ?? 'متجر',
      coverUrl: json['store_banner_url'] ?? json['cover_image'],
      profileUrl: json['profile_picture_url'] ?? json['profile_image'],
      bio: json['bio'],
      rating: double.parse((json['rating'] ?? 0).toString()),
      location: json['location'] ?? json['city'],
      followersCount: json['followers_count'] ?? 0,
      totalSales:
          json['total_sales'] ?? 0, // تأكد من أن الباك إند يرسل هذا الرقم
      activeProductsCount: json['products_count'] ?? productsList.length,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isDropshipper:
          json['is_dropshipper'] == true || json['is_dropshipper'] == 1,
      products: productsList,
    );
  }
}
