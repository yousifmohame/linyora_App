enum UserRole {
  admin,      // المدير
  merchant,   // التاجر
  model,      // المودل / المؤثرة
  supplier,   // المورد
  customer,   // العميل العادي
  unknown     // غير معروف
}

class UserModel {
  final int id;
  final String name;
  final String? email;
  final UserRole role; // غيرنا النوع هنا ليكون Enum
  final String? avatar;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.role,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'],
      // تحويل رقم الدور أو اسمه من السيرفر إلى Enum
      // ملاحظة: يجب التأكد من القيم الحقيقية في قاعدة البيانات (role_id)
      role: _parseRole(json['role_id'] ?? json['role']), 
      avatar: json['profile_picture_url'],
    );
  }

  // دالة مساعدة لتحويل الرقم إلى دور
  static UserRole _parseRole(dynamic roleId) {
    // افترضنا هذه القيم بناءً على الشائع، يمكن تعديلها حسب الداتابيز لديك
    switch (roleId.toString()) {
      case '1': return UserRole.admin;
      case '2': return UserRole.merchant;
      case '3': return UserRole.model; // أو المؤثرة
      case '4': return UserRole.supplier;
      case '5': return UserRole.customer;
      default: return UserRole.customer; // الافتراضي عميل
    }
  }
}