import 'product_model.dart';

class ReelModel {
  final int id;
  final String videoUrl;
  final String? description;
  final String? thumbnailUrl;
  bool isLiked;
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
      description: json['caption'],
      isLiked: (json['isLikedByMe'] == true || json['isLikedByMe'] == 1),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      user: UserModel.fromJson(
        json,
      ), // تمرير الـ json كاملاً لاستخراج بيانات المستخدم
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
  bool isFollowing; // ✅ تمت الإضافة: متغير حالة المتابعة (قابل للتعديل)

  UserModel({
    required this.id,
    required this.name,
    required this.avatar,
    this.isFollowing = false, // القيمة الافتراضية
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 1. الحالة الأولى: البيانات مسطحة (Flat structure) كما في بعض ردود الـ API
    if (json.containsKey('userId')) {
      return UserModel(
        id:
            json['userId'] is int
                ? json['userId']
                : int.tryParse(json['userId'].toString()) ?? 0,
        name: json['userName'] ?? 'User',
        avatar: json['userAvatar'] ?? '',
        // ✅ قراءة حالة المتابعة (قد تأتي باسم isFollowedByMe أو isFollowing)
        isFollowing:
            (json['isFollowedByMe'] == true || json['isFollowing'] == true),
      );
    }
    // 2. الحالة الثانية: البيانات داخل كائن 'user' أو 'model'
    else if (json.containsKey('user') || json.containsKey('model')) {
      final userData = json['user'] ?? json['model'];
      return UserModel(
        id:
            userData['id'] is int
                ? userData['id']
                : int.tryParse(userData['id'].toString()) ?? 0,
        name: userData['name'] ?? 'User',
        avatar: userData['profile_picture_url'] ?? userData['avatar'] ?? '',
        // ✅ قراءة الحالة من الكائن الداخلي
        isFollowing:
            (userData['isFollowedByMe'] == true ||
                userData['isFollowing'] == true),
      );
    }

    // حالة افتراضية
    return UserModel(
      id: 0,
      name: 'Linyora User',
      avatar: '',
      isFollowing: false,
    );
  }
}
