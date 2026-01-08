// تعريف الأدوار
enum UserRole {
  admin, // 1
  merchant, // 2
  model, // 3
  supplier, // 4
  customer, // 5
  unknown,
}

class UserModel {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? token;

  // نخزن الرقم كما يأتي من الباك إند
  final int roleId;

  // حقول التاجر
  final String verificationStatus;
  final bool hasAcceptedAgreement;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.token,
    this.roleId = 5, // الافتراضي عميل
    this.verificationStatus = 'not_submitted',
    this.hasAcceptedAgreement = false,
  });

  // --- أهم جزء: Getter يحول الرقم لـ Enum ---
  UserRole get role {
    switch (roleId) {
      case 1:
        return UserRole.admin;
      case 2:
        return UserRole.merchant;
      case 3:
        return UserRole.model; // المودل
      case 4:
        return UserRole.supplier; // المورد (أو الانفلونسر حسب التسمية لديك)
      case 5:
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }

  // دوال مساعدة للاستخدام السريع
  bool get isMerchant => role == UserRole.merchant;
  bool get isModel => role == UserRole.model;
  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? json['mobile'],
      avatar: json['profile_picture_url'] ?? json['avatar'],
      token: json['access_token'] ?? json['token'],

      // قراءة الـ role_id بمرونة (سواء جاء كنص أو رقم)
      roleId:
          json['role_id'] is int
              ? json['role_id']
              : int.tryParse(json['role_id']?.toString() ?? '5') ?? 5,

      verificationStatus: json['verification_status'] ?? 'not_submitted',
      hasAcceptedAgreement:
          json['has_accepted_agreement'] == 1 ||
          json['has_accepted_agreement'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role_id': roleId,
      'profile_picture_url': avatar,
      'token': token,
      'verification_status': verificationStatus,
      'has_accepted_agreement': hasAcceptedAgreement,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? token,
    int? roleId,
    String? verificationStatus,
    bool? hasAcceptedAgreement,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      token: token ?? this.token,
      roleId: roleId ?? this.roleId,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      hasAcceptedAgreement: hasAcceptedAgreement ?? this.hasAcceptedAgreement,
    );
  }
}
