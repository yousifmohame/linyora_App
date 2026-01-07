enum UserRole {
  admin, // 1
  merchant, // 2
  model, // 3
  supplier, // 4
  customer, // 5
  unknown, // غير معروف
}

class UserModel {
  final int id;
  final String name;
  final String? email;
  final String? phone; // 1. تمت الإضافة
  final UserRole role;
  final String? avatar;
  final String? token; // 2. تمت الإضافة (اختياري حسب الـ API)

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    this.avatar,
    this.token,
  });

  // --- من JSON إلى Dart ---
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? json['mobile'], // للتوافق مع مسميات مختلفة
      role: _parseRole(json['role_id'] ?? json['role']),
      avatar: json['profile_picture_url'] ?? json['avatar'],
      token: json['access_token'] ?? json['token'], // التقاط التوكن
    );
  }

  // --- 3. دالة toJson (من Dart إلى JSON) ---
  // مهمة جداً عند حفظ البيانات محلياً أو إرسالها للسيرفر
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role_id': _roleToId(role), // تحويل الـ Enum لرقم مرة أخرى
      'profile_picture_url': avatar,
      'token': token,
    };
  }

  // --- 4. دالة copyWith (للتعديل الآمن) ---
  // تسمح لك بتحديث حقل واحد وإنشاء نسخة جديدة
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatar,
    UserRole? role,
    String? token,
  }) {
    return UserModel(
      id: this.id, // الـ ID لا يتغير عادة
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      token: token ?? this.token,
    );
  }

  // Helper: تحويل الرقم إلى Enum
  static UserRole _parseRole(dynamic roleId) {
    if (roleId == null) return UserRole.customer;
    String idString = roleId.toString();

    switch (idString) {
      case '1':
        return UserRole.admin;
      case '2':
        return UserRole.merchant;
      case '3':
        return UserRole.model;
      case '4':
        return UserRole.supplier;
      case '5':
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }

  // Helper: تحويل Enum إلى رقم (للاستخدام في toJson)
  int _roleToId(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 1;
      case UserRole.merchant:
        return 2;
      case UserRole.model:
        return 3;
      case UserRole.supplier:
        return 4;
      case UserRole.customer:
        return 5;
      default:
        return 5;
    }
  }
}
