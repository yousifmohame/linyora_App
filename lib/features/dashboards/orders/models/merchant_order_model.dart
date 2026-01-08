class MerchantOrderSummary {
  final int orderId;
  final String orderStatus;
  final DateTime orderDate;
  final String customerName;
  final String customerEmail;
  final double totalAmount;
  final String productsSummary; // أسماء المنتجات مفصولة بفواصل

  MerchantOrderSummary({
    required this.orderId,
    required this.orderStatus,
    required this.orderDate,
    required this.customerName,
    required this.customerEmail,
    required this.totalAmount,
    required this.productsSummary,
  });

  factory MerchantOrderSummary.fromJson(Map<String, dynamic> json) {
    return MerchantOrderSummary(
      orderId: json['orderId'] is int ? json['orderId'] : int.parse(json['orderId'].toString()),
      orderStatus: json['orderStatus'] ?? 'pending',
      orderDate: DateTime.tryParse(json['orderDate'].toString()) ?? DateTime.now(),
      customerName: json['customerName'] ?? 'Unknown',
      customerEmail: json['customerEmail'] ?? '',
      totalAmount: double.tryParse(json['totalAmount'].toString()) ?? 0.0,
      productsSummary: json['products'] ?? '',
    );
  }
}