// نموذج العنوان
import 'package:linyora_project/models/cart_item_model.dart';

class AddressModel {
  final int id;
  final String fullName;
  final String phone;
  final String city;
  final String addressLine1;

  // ✨ الحقول الجديدة التي يجب إضافتها
  final String? state; // state_province_region
  final String? postalCode; // postal_code
  final String? country;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.city,
    required this.addressLine1,
    this.state,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      phone:
          json['phone_number'] ??
          '', // تأكد أن الاسم يطابق الباك إند phone_number
      city: json['city'] ?? '',
      addressLine1: json['address_line_1'] ?? '',

      // ✅ قراءة الحقول الجديدة من الـ JSON
      state: json['state_province_region'], // الاسم في قاعدة البيانات
      postalCode: json['postal_code'], // الاسم في قاعدة البيانات
      country: json['country'],

      // تحويل الإحداثيات بأمان (قد تأتي String أو Double)
      latitude:
          json['latitude'] != null
              ? double.tryParse(json['latitude'].toString())
              : null,
      longitude:
          json['longitude'] != null
              ? double.tryParse(json['longitude'].toString())
              : null,

      isDefault: (json['is_default'] == 1 || json['is_default'] == true),
    );
  }
}

class ShippingOption {
  final int id;
  final String name;
  final double cost;
  final String? estimatedDays;

  ShippingOption({
    required this.id,
    required this.name,
    required this.cost,
    this.estimatedDays,
  });

  factory ShippingOption.fromJson(Map<String, dynamic> json) {
    return ShippingOption(
      id: json['id'],
      name: json['name'],
      cost: double.parse(json['shipping_cost'].toString()),
      estimatedDays: json['estimated_days']?.toString(),
    );
  }
}

class MerchantGroup {
  final String groupId; // merchantId or supplierId
  final String merchantName;
  final List<CartItemModel> items;
  List<ShippingOption> shippingOptions; // خيارات الشحن المتاحة لهذا التاجر
  ShippingOption? selectedShipping; // الخيار الذي حدده المستخدم

  MerchantGroup({
    required this.groupId,
    required this.merchantName,
    required this.items,
    this.shippingOptions = const [],
    this.selectedShipping,
  });
}
