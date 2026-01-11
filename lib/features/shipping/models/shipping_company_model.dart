class ShippingCompany {
  final int id;
  final String name;
  final double shippingCost;
  final bool isActive;
  final String deliveryTime;
  final String createdAt;

  ShippingCompany({
    required this.id,
    required this.name,
    required this.shippingCost,
    required this.isActive,
    required this.deliveryTime,
    required this.createdAt,
  });

  factory ShippingCompany.fromJson(Map<String, dynamic> json) {
    return ShippingCompany(
      id: json['id'],
      name: json['name'] ?? '',
      // التعامل الآمن مع الأرقام (قد تأتي كنص أو رقم)
      shippingCost: double.tryParse(json['shipping_cost'].toString()) ?? 0.0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      deliveryTime: json['delivery_time'] ?? '3-5 أيام',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'shipping_cost': shippingCost,
      'is_active': isActive,
      'delivery_time': deliveryTime,
    };
  }
}