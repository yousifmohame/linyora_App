import 'product_model.dart'; // تأكد من استيراد موديل المنتج

class ReelModel {
  final int id;
  final String videoUrl;
  final String? description; // caption in backend
  final String? thumbnailUrl;
  bool isLiked; // متغير قابل للتغيير ليعكس حالة isLikedByMe
  int likesCount;
  int commentsCount;
  final UserModel? user;
  final List<ProductModel>? products;

  ReelModel({
    required this.id,
    required this.videoUrl,
    this.description,
    this.thumbnailUrl,
    this.isLiked = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.user,
    this.products,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      description: json['caption'], // الباك اند يرسلها باسم caption
      // هنا الإصلاح لمشكلة عدم حفظ حالة اللايك
      isLiked: (json['isLikedByMe'] == true || json['isLikedByMe'] == 1),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,

      // هنا الإصلاح لمشكلة عدم ظهور بيانات المستخدم
      // البيانات تأتي مباشرة في الروت وليس داخل كائن 'model'
      user: UserModel.fromJson(json),

      products:
          json['tagged_products'] != null
              ? (json['tagged_products'] as List)
                  .map((i) => ProductModel.fromJson(i))
                  .toList()
              : [],
    );
  }
}

class UserModel {
  final int id;
  final String name;
  final String avatar;

  UserModel({required this.id, required this.name, required this.avatar});

  // الباك اند يرسل البيانات باسم userId, userName, userAvatar
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // نتحقق مما إذا كانت البيانات مجمعة أو منفصلة
    if (json.containsKey('userId')) {
      return UserModel(
        id:
            json['userId'] is int
                ? json['userId']
                : int.parse(json['userId'].toString()),
        name: json['userName'] ?? 'User',
        avatar: json['userAvatar'] ?? '',
      );
    }
    // حالة احتياطية لو تغير الباك اند
    else if (json.containsKey('user')) {
      final userJson = json['user'];
      return UserModel(
        id: userJson['id'],
        name: userJson['name'],
        avatar: userJson['profile_picture_url'] ?? '',
      );
    }

    return UserModel(id: 0, name: 'Linyora User', avatar: '');
  }
}
