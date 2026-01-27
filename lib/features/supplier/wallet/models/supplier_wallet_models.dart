class SupplierWallet {
  final double balance;
  final double pendingClearance;
  final List<PayoutRequest> payouts;

  SupplierWallet({
    required this.balance,
    required this.pendingClearance,
    required this.payouts,
  });

  factory SupplierWallet.fromJson(Map<String, dynamic> json) {
    return SupplierWallet(
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      pendingClearance: double.tryParse(json['pending_clearance']?.toString() ?? '0') ?? 0.0,
      payouts: (json['payouts'] as List?)
          ?.map((e) => PayoutRequest.fromJson(e))
          .toList() ?? [],
    );
  }
}

class PayoutRequest {
  final int id;
  final double amount;
  final String status;
  final String createdAt;
  final String? notes;

  PayoutRequest({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  factory PayoutRequest.fromJson(Map<String, dynamic> json) {
    return PayoutRequest(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      notes: json['notes'],
    );
  }
}

class WalletTransaction {
  final String id;
  final double amount;
  final String type; // 'earning' or 'payout'
  final String status;
  final String description;
  final String date;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    required this.date,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      type: json['type'] ?? 'earning',
      status: json['status'] ?? 'pending',
      description: json['description'] ?? '',
      date: json['created_at'] ?? '',
    );
  }
}