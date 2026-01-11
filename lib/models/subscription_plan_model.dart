class SubscriptionPlan {
  final int id;
  final String name;
  final String description;
  final double price;
  final List<String> features;
  final bool includesDropshipping;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.features,
    required this.includesDropshipping,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      // تحويل السعر بأمان سواء جاء كنص أو رقم
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      // تحويل قائمة الميزات
      features:
          json['features'] != null ? List<String>.from(json['features']) : [],
      includesDropshipping:
          json['includes_dropshipping'] == true ||
          json['includes_dropshipping'] == 1,
    );
  }
}
