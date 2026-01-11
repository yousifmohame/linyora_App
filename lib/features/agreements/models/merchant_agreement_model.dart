class MerchantAgreement {
  final int id;
  final String
  status; // pending, accepted, in_progress, delivered, completed, rejected
  final String modelName;
  final String packageTitle;
  final double tierPrice;
  final String createdAt;
  final bool hasMerchantReviewed;

  MerchantAgreement({
    required this.id,
    required this.status,
    required this.modelName,
    required this.packageTitle,
    required this.tierPrice,
    required this.createdAt,
    required this.hasMerchantReviewed,
  });

  factory MerchantAgreement.fromJson(Map<String, dynamic> json) {
    return MerchantAgreement(
      id: json['id'],
      status: json['status'] ?? 'pending',
      modelName: json['modelName'] ?? '',
      packageTitle: json['packageTitle'] ?? '',
      // تحويل السعر بأمان
      tierPrice: double.tryParse(json['tierPrice'].toString()) ?? 0.0,
      createdAt: json['created_at'] ?? '',

      // --- التعديل هنا (الحل الجذري) ---
      // نقبل القيمة إذا كانت true أو إذا كانت رقم 1
      hasMerchantReviewed:
          json['hasMerchantReviewed'] == true ||
          json['hasMerchantReviewed'] == 1,
    );
  }
}
