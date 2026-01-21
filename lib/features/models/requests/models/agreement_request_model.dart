class AgreementRequest {
  final int id;
  final String merchantName;
  final String? merchantAvatar;
  final String productName;
  final String? productImage;
  final String packageTitle;
  final String tierName;
  final double tierPrice;
  final int deliveryDays;
  final int revisions;
  final List<String> features;
  String status; // pending, accepted, rejected, in_progress, delivered, completed
  final String createdAt;
  final String? merchantLocation;
  final String? priority; // low, medium, high

  AgreementRequest({
    required this.id,
    required this.merchantName,
    this.merchantAvatar,
    required this.productName,
    this.productImage,
    required this.packageTitle,
    required this.tierName,
    required this.tierPrice,
    required this.deliveryDays,
    required this.revisions,
    required this.features,
    required this.status,
    required this.createdAt,
    this.merchantLocation,
    this.priority,
  });

  factory AgreementRequest.fromJson(Map<String, dynamic> json) {
    return AgreementRequest(
      id: json['id'],
      merchantName: json['merchantName'] ?? 'تاجر',
      merchantAvatar: json['merchantAvatar'],
      productName: json['productName'] ?? 'منتج',
      productImage: json['productImage'],
      packageTitle: json['packageTitle'] ?? 'عرض',
      tierName: json['tierName'] ?? 'أساسي',
      tierPrice: double.tryParse(json['tierPrice'].toString()) ?? 0.0,
      deliveryDays: int.tryParse(json['deliveryDays'].toString()) ?? 1,
      revisions: int.tryParse(json['revisions'].toString()) ?? 0,
      features: (json['features'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      merchantLocation: json['merchantLocation'],
      priority: json['priority'],
    );
  }
}