import '../core/utils/image_helper.dart';

class SectionSlide {
  final String title;
  final String description;
  final String imageUrl;
  final String mediaType; // 'image' or 'video'
  final String buttonText;
  final String buttonLink;

  SectionSlide({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.mediaType,
    required this.buttonText,
    required this.buttonLink,
  });

  factory SectionSlide.fromJson(Map<String, dynamic> json) {
    return SectionSlide(
      title: json['title_ar'] ?? json['title_en'] ?? '',
      description: json['description_ar'] ?? json['description_en'] ?? '',
      imageUrl: ImageHelper.getValidUrl(json['image_url']),
      mediaType: json['media_type'] ?? 'image',
      buttonText: json['button_text_ar'] ?? json['button_text_en'] ?? '',
      buttonLink: json['button_link'] ?? '',
    );
  }
}

class SectionCategory {
  final int id;
  final String name;
  final String slug;
  final String imageUrl;

  SectionCategory({required this.id, required this.name, required this.slug, required this.imageUrl});

  factory SectionCategory.fromJson(Map<String, dynamic> json) {
    return SectionCategory(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      imageUrl: ImageHelper.getValidUrl(json['image_url']),
    );
  }
}

class SectionModel {
  final int id;
  final String title;
  final String description;
  final String icon;
  final String themeColor;
  final bool isActive;
  
  // Featured Product Data
  final int? featuredProductId;
  final String? productName;
  final String? productImage;
  final double? productPrice;
  final String? productDescription;

  // Lists
  final List<SectionSlide> slides;
  final List<SectionCategory> categories;

  SectionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.themeColor,
    required this.isActive,
    this.featuredProductId,
    this.productName,
    this.productImage,
    this.productPrice,
    this.productDescription,
    required this.slides,
    required this.categories,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'],
      title: json['title_ar'] ?? json['title_en'] ?? '',
      description: json['description_ar'] ?? json['description_en'] ?? '',
      icon: ImageHelper.getValidUrl(json['icon']),
      themeColor: json['theme_color'] ?? '#ea580c', // اللون الافتراضي (برتقالي)
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      
      // المنتج المميز
      featuredProductId: json['featured_product_id'], // قد يكون null
      productName: json['product_name_ar'] ?? json['product_name_en'],
      productImage: json['product_image'] != null ? ImageHelper.getValidUrl(json['product_image']) : null,
      productPrice: double.tryParse(json['product_price'].toString()),
      productDescription: json['product_description'],

      // القوائم
      slides: (json['slides'] as List? ?? [])
          .map((e) => SectionSlide.fromJson(e))
          .toList(),
      categories: (json['categories'] as List? ?? [])
          .map((e) => SectionCategory.fromJson(e))
          .toList(),
    );
  }
}