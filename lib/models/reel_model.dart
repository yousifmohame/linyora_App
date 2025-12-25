class ReelModel {
  final int id;
  final String videoUrl;
  final String? description;
  final int likesCount;
  final int commentsCount;
  final UserModel? user; // Model/Influencer data
  final List<ProductModel>? products; // Products linked to this reel

  ReelModel({
    required this.id,
    required this.videoUrl,
    this.description,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.user,
    this.products,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'],
      videoUrl: json['video_url'] ?? '', // تأكد من اسم الحقل في الـ API response
      description: json['description'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      // تأكد من تطابق هذه الحقول مع رد الـ Backend
      user: json['model'] != null ? UserModel.fromJson(json['model']) : null,
      products: json['products'] != null 
          ? (json['products'] as List).map((i) => ProductModel.fromJson(i)).toList() 
          : [],
    );
  }
}

// ستحتاج لتعريف UserModel و ProductModel بشكل مشابه بناءً على بياناتك
class UserModel {
  final String name;
  final String avatar;
  UserModel({required this.name, required this.avatar});
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'] ?? 'User',
    avatar: json['avatar'] ?? '',
  );
}

class ProductModel {
  final int id;
  final String name;
  final String image;
  final double price;
  ProductModel({required this.id, required this.name, required this.image, required this.price});
  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'],
    name: json['name'],
    image: json['image'],
    price: double.parse(json['price'].toString()),
  );
}