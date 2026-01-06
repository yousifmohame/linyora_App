class WalletModel {
  final int totalPoints;
  final double equivalentAmount; // القيمة المالية للنقاط (اختياري)
  final List<WalletTransaction> transactions;

  WalletModel({
    required this.totalPoints,
    required this.equivalentAmount,
    required this.transactions,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      totalPoints: json['total_points'] ?? 0,
      equivalentAmount: double.tryParse(json['equivalent_amount'].toString()) ?? 0.0,
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => WalletTransaction.fromJson(e))
          .toList(),
    );
  }
}

class WalletTransaction {
  final int id;
  final String title; // "شراء منتج"، "مكافأة تسجيل"
  final int points; // يمكن أن يكون موجب أو سالب
  final String type; // 'credit' (إضافة) أو 'debit' (خصم)
  final String date;

  WalletTransaction({
    required this.id,
    required this.title,
    required this.points,
    required this.type,
    required this.date,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      title: json['description'] ?? 'عملية نقاط',
      points: json['points'] ?? 0,
      type: json['type'] ?? 'credit',
      date: json['created_at'] ?? '',
    );
  }

  // معرفة هل العملية إضافة أم خصم
  bool get isCredit => type == 'credit' || points > 0;
}