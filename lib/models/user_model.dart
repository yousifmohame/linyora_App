// ✅ حالة الاشتراك (محدث)
class SubscriptionState {
  final String status;
  final bool hasDropshippingAccess;
  final int? planId; // ✅ 1. الحقل الجديد
  final String? planName;
  final String? startDate;
  final String? endDate;

  SubscriptionState({
    this.status = 'inactive',
    this.hasDropshippingAccess = false,
    this.planId, // ✅ إضافته للكونستركتور
    this.planName,
    this.startDate,
    this.endDate,
  });

  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    return SubscriptionState(
      status: json['status'] ?? 'inactive',
      hasDropshippingAccess:
          json['permissions']?['hasDropshippingAccess'] ?? false,

      // ✅ 2. قراءة الـ ID من داخل كائن 'plan' بشكل آمن
      planId: int.tryParse(json['plan']?['id']?.toString() ?? ''),

      planName: json['plan']?['name'],
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }
}

// ✅ أدوار المستخدم (تحديث التعليقات للتوضيح)
enum UserRole {
  admin, // 1
  merchant, // 2
  model, // 3
  influencer, //4
  customer, // 5
  supplier, // 6 ✅ (تم التحديث)
  unknown,
}

// ✅ مودل المستخدم الموحد
class UserModel {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? token;
  final int points;

  // رقم الدور من الباك إند
  final int roleId;

  // حقول التاجر
  final String verificationStatus;
  final bool hasAcceptedAgreement;

  // حالة الاشتراك
  final SubscriptionState? subscription;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.token,
    this.points = 0,
    this.roleId = 5, // الافتراضي عميل
    this.verificationStatus = 'not_submitted',
    this.hasAcceptedAgreement = false,
    this.subscription,
  });

  // --- 🔄 Getter لتحويل الرقم لـ Enum (تم التعديل هنا) ---
  UserRole get role {
    switch (roleId) {
      case 1:
        return UserRole.admin;
      case 2:
        return UserRole.merchant;
      case 3:
        return UserRole.model;
      case 4:
        return UserRole.influencer;
      case 5:
        return UserRole.customer;
      case 6:
        return UserRole.supplier; // ✅ تم تعيين رقم 6 للمورد
      default:
        return UserRole.customer;
    }
  }

  // دوال مساعدة للاستخدام السريع
  bool get isMerchant => role == UserRole.merchant;
  bool get isModel => role == UserRole.model;
  bool get isInfluencer => role == UserRole.influencer;
  bool get isAdmin => role == UserRole.admin;
  bool get isSupplier => role == UserRole.supplier; // ✅ دالة مساعدة للمورد
  bool get isCustomer => role == UserRole.customer;

  // هل المستخدم مشترك؟
  bool get isSubscribed => subscription?.status == 'active';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 🔍 LOG: طباعة البيانات للتأكد
    print("================ DEBUG USER MODEL ================");
    print("User Name: ${json['name']}");
    print("Role ID: ${json['role_id']}"); // تأكد أن هذا يطبع 6 للمورد

    if (json['subscription'] != null) {
      print("Sub Status: ${json['subscription']['status']}");
    }
    print("==================================================");

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
      points: json['points'] ?? 0,

      // قراءة Role ID
      roleId:
          json['role_id'] is int
              ? json['role_id']
              : int.tryParse(json['role_id']?.toString() ?? '5') ?? 5,

      verificationStatus: json['verification_status'] ?? 'not_submitted',

      hasAcceptedAgreement:
          json['has_accepted_agreement'] == 1 ||
          json['has_accepted_agreement'] == true,

      subscription:
          json['subscription'] != null
              ? SubscriptionState.fromJson(json['subscription'])
              : null,
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
    SubscriptionState? subscription,
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
      subscription: subscription ?? this.subscription,
    );
  }
}
