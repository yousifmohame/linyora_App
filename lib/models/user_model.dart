// ✅ حالة الاشتراك (منقولة من كودك)
class SubscriptionState {
  final String status;
  final bool hasDropshippingAccess;
  final String? planName;
  // ✅ الحقول الجديدة من اللوج
  final String? startDate;
  final String? endDate;

  SubscriptionState({
    this.status = 'inactive',
    this.hasDropshippingAccess = false,
    this.planName,
    this.startDate,
    this.endDate,
  });

  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    return SubscriptionState(
      status: json['status'] ?? 'inactive',
      hasDropshippingAccess:
          json['permissions']?['hasDropshippingAccess'] ?? false,
      // قراءة الاسم من داخل الكائن المتداخل plan
      planName: json['plan']?['name'],
      // قراءة التواريخ
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }
}

// ✅ أدوار المستخدم
enum UserRole {
  admin, // 1
  merchant, // 2
  model, // 3
  supplier, // 4
  customer, // 5
  unknown,
}

// ✅ مودل المستخدم الموحد (مدمج)
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

  // ✅ الحقل الجديد: حالة الاشتراك
  final SubscriptionState? subscription;

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
    this.subscription,
  });

  // --- Getter لتحويل الرقم لـ Enum ---
  UserRole get role {
    switch (roleId) {
      case 1:
        return UserRole.admin;
      case 2:
        return UserRole.merchant;
      case 3:
        return UserRole.model;
      case 4:
        return UserRole.supplier;
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

  // ✅ هل المستخدم مشترك؟
  bool get isSubscribed => subscription?.status == 'active';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 🔍 LOG 1: طباعة البيانات الخام القادمة من السيرفر
    print("================ DEBUG USER MODEL ================");
    print("User Name: ${json['name']}");
    print("Raw Subscription Data: ${json['subscription']}");
    print("Role ID: ${json['role_id']}");

    // فحص محتوى الاشتراك بالتفصيل
    if (json['subscription'] != null) {
      print("Sub Status: ${json['subscription']['status']}");
      print("Sub Permissions: ${json['subscription']['permissions']}");
    } else {
      print("❌ Subscription is NULL in JSON!");
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

      roleId:
          json['role_id'] is int
              ? json['role_id']
              : int.tryParse(json['role_id']?.toString() ?? '5') ?? 5,

      verificationStatus: json['verification_status'] ?? 'not_submitted',

      hasAcceptedAgreement:
          json['has_accepted_agreement'] == 1 ||
          json['has_accepted_agreement'] == true,

      // قراءة الاشتراك
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
      // لا نحتاج لإرسال الاشتراك للباك إند غالباً، لكن يمكن إضافته إذا لزم
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
