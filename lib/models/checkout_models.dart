// نموذج العنوان
class AddressModel {
  final int id;
  final String fullName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String phone;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.fullName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.phone,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      addressLine1: json['address_line_1'] ?? '',
      addressLine2: json['address_line_2'],
      city: json['city'] ?? '',
      phone: json['phone_number'] ?? '',
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }
}

// نموذج خيار الشحن
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
      estimatedDays: json['estimated_days'],
    );
  }
}
