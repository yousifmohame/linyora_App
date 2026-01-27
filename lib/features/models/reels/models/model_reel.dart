class TaggedProduct {
  final int id;
  final String name;
  final String? imageUrl;

  TaggedProduct({required this.id, required this.name, this.imageUrl});

  factory TaggedProduct.fromJson(Map<String, dynamic> json) {
    return TaggedProduct(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
    );
  }
}

class ModelReel {
  final int id;
  final String videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final int viewsCount;
  final int likesCount;
  final bool isActive;
  final int? agreementId;
  final List<TaggedProduct>? taggedProducts;
  final String createdAt;

  ModelReel({
    required this.id,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.caption,
    required this.viewsCount,
    required this.likesCount,
    required this.isActive,
    this.agreementId,
    this.taggedProducts,
    required this.createdAt,
  });

  factory ModelReel.fromJson(Map<String, dynamic> json) {
    return ModelReel(
      id: json['id'],
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      caption: json['caption'] ?? '',
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      agreementId: json['agreement_id'],
      taggedProducts: json['tagged_products'] != null
          ? (json['tagged_products'] as List)
              .map((i) => TaggedProduct.fromJson(i))
              .toList()
          : [],
      createdAt: json['created_at'] ?? '',
    );
  }
}