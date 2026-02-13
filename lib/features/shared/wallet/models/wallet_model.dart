class WalletData {
  final double balance;
  final double pendingBalance; // تم تغيير الاسم ليتطابق مع الباك إند
  final double totalEarnings;
  final double outstandingDebt; // حقل جديد للمديونيات
  final int pendingTransactionsCount; // عدد العمليات المعلقة

  WalletData({
    required this.balance,
    required this.pendingBalance,
    required this.totalEarnings,
    required this.outstandingDebt,
    required this.pendingTransactionsCount,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      pendingBalance: double.tryParse(json['pending_balance'].toString()) ??
          double.tryParse(json['pending_clearance'].toString()) ?? 0.0,
      totalEarnings: double.tryParse(json['total_earnings'].toString()) ?? 0.0,
      outstandingDebt: double.tryParse(json['outstanding_debt'].toString()) ?? 0.0,
      pendingTransactionsCount: int.tryParse(json['pending_transactions_count'].toString()) ?? 0,
    );
  }
}

class WalletTransaction {
  final int id;
  final double amount;
  final String type; // sale_earning, cod_commission_deduction, payout, etc.
  final String status; // cleared, pending, cancelled
  final String description;
  final String? referenceId; // رقم المرجع (الطلب/الاتفاق)
  final String createdAt;
  final String? availableAt; // تاريخ الاستحقاق

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    this.referenceId,
    required this.createdAt,
    this.availableAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      type: json['type'] ?? 'unknown',
      status: json['status'] ?? 'pending',
      description: json['description'] ?? '',
      referenceId: json['reference_id']?.toString(),
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      availableAt: json['available_at'],
    );
  }
}