import 'dart:convert'; // ✅ ضروري لفك تشفير النصوص

class PackageTier {
  int? id;
  String tierName;
  double price;
  int deliveryDays;
  int revisions; // -1 means unlimited
  List<String> features;

  PackageTier({
    this.id,
    required this.tierName,
    required this.price,
    required this.deliveryDays,
    required this.revisions,
    required this.features,
  });

  factory PackageTier.fromJson(Map<String, dynamic> json) {
    // 🔥 حل المشكلة هنا: معالجة مرنة لحقل المميزات
    List<String> parsedFeatures = [];

    if (json['features'] != null) {
      if (json['features'] is List) {
        // الحالة 1: البيانات جاءت كقائمة جاهزة
        parsedFeatures =
            (json['features'] as List).map((e) => e.toString()).toList();
      } else if (json['features'] is String) {
        // الحالة 2: البيانات جاءت كنص (JSON String) يجب فكه
        try {
          // إزالة الأقواس الزائدة أو التنظيف إذا لزم الأمر، ثم التحويل
          var decoded = jsonDecode(json['features']);
          if (decoded is List) {
            parsedFeatures = decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          print("Error parsing features string: $e");
        }
      }
    }

    return PackageTier(
      id: json['id'],
      tierName: json['tier_name'] ?? 'Basic',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      deliveryDays: int.tryParse(json['delivery_days'].toString()) ?? 1,
      revisions: int.tryParse(json['revisions'].toString()) ?? -1,
      features: parsedFeatures,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tier_name': tierName,
    'price': price,
    'delivery_days': deliveryDays,
    'revisions': revisions,
    'features': features,
  };
}

class ServicePackage {
  int id;
  String title;
  String? description;
  String? category;
  String status; // 'active' or 'paused'
  List<PackageTier> tiers;

  ServicePackage({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.status,
    required this.tiers,
  });

  factory ServicePackage.fromJson(Map<String, dynamic> json) {
    // 🔥 حماية إضافية لحقل tiers أيضاً
    List<PackageTier> parsedTiers = [];

    var tiersData = json['tiers'];

    if (tiersData != null) {
      if (tiersData is String) {
        try {
          tiersData = jsonDecode(tiersData);
        } catch (e) {
          print("Error parsing tiers string: $e");
          tiersData = [];
        }
      }

      if (tiersData is List) {
        parsedTiers = tiersData.map((e) => PackageTier.fromJson(e)).toList();
      }
    }

    return ServicePackage(
      id:
          json['id'] is String
              ? int.tryParse(json['id']) ?? 0
              : json['id'] ?? 0,
      title: json['title'] ?? 'Untitled',
      description: json['description'],
      category: json['category'],
      status: json['status'] ?? 'active',
      tiers: parsedTiers,
    );
  }
}
