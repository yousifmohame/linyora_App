class ModelWallet {
  final double balance;
  final double pendingClearance;
  final double totalEarnings; // يمكن حسابها أو جلبها

  ModelWallet({
    required this.balance,
    required this.pendingClearance,
    this.totalEarnings = 0.0,
  });

  factory ModelWallet.fromJson(Map<String, dynamic> json) {
    return ModelWallet(
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      pendingClearance: double.tryParse(json['pending_clearance'].toString()) ?? 0.0,
      totalEarnings: double.tryParse(json['total_earnings'].toString()) ?? 0.0,
    );
  }
}

class Transaction {
  final int id;
  final double amount;
  final String type; // 'earning', 'payout', 'refund'
  final String description;
  final String date;
  final String status; // 'approved', 'pending', 'failed'

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    required this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      type: json['type'] ?? 'earning',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}