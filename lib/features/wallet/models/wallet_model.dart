class WalletData {
  final double balance;
  final double pendingClearance;
  final double totalEarnings;
  final String? lastPayout;

  WalletData({
    required this.balance,
    required this.pendingClearance,
    required this.totalEarnings,
    this.lastPayout,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      pendingClearance:
          double.tryParse(json['pending_clearance'].toString()) ?? 0.0,
      totalEarnings: double.tryParse(json['total_earnings'].toString()) ?? 0.0,
      lastPayout: json['last_payout'],
    );
  }
}

class WalletTransaction {
  final int id;
  final double amount;
  final String type; // 'payout', 'earning', 'refund'
  final String status; // 'completed', 'pending', 'failed'
  final String description;
  final String createdAt;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      // تحويل آمن للـ id
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,

      // تحويل آمن للـ amount (يقبل String أو int أو double)
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,

      type: json['type'] ?? 'earning',
      status: json['status'] ?? 'pending',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}
