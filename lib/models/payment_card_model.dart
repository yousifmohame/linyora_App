class PaymentCardModel {
  final String id; // أصبح String ليتوافق مع Stripe ID
  final String last4;
  final String brand;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  PaymentCardModel({
    required this.id,
    required this.last4,
    required this.brand,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
  });

  factory PaymentCardModel.fromJson(Map<String, dynamic> json) {
    return PaymentCardModel(
      id: json['id'],
      last4: json['last4'] ?? '0000',
      brand: json['brand'] ?? 'card',
      expMonth: json['exp_month'] ?? 1,
      expYear: json['exp_year'] ?? 2025,
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }

  // دالة مساعدة لتحويل التاريخ لتنسيق العرض MM/YY
  String get expiryDateFormatted {
    String month = expMonth.toString().padLeft(2, '0');
    String year = expYear.toString().substring(2); // نأخذ آخر رقمين من السنة
    return '$month/$year';
  }
}