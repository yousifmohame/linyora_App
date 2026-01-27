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
      // ✅ تحسين: تحويل آمن للـ id مثل السعر
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      
      // السعر (ممتاز)
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      
      // الميزات (ممتاز)
      features: json['features'] != null 
          ? List<String>.from(json['features']) 
          : [],
          
      // الدروب شيبينج (ممتاز)
      includesDropshipping:
          json['includes_dropshipping'] == true ||
          json['includes_dropshipping'] == 1,
    );
  }
}