class MerchantDashboardData {
  final double totalSales;
  final int totalProducts;
  final int activeProducts;
  final double averageRating;
  final int totalReviews;
  final int monthlyViews;
  final List<SalesData> weeklySales;
  final List<SalesData> monthlySales;
  final List<RecentOrder> recentOrders;

  MerchantDashboardData({
    required this.totalSales,
    required this.totalProducts,
    required this.activeProducts,
    required this.averageRating,
    required this.totalReviews,
    required this.monthlyViews,
    required this.weeklySales,
    required this.monthlySales,
    required this.recentOrders,
  });

  factory MerchantDashboardData.fromJson(Map<String, dynamic> json) {
    return MerchantDashboardData(
      totalSales: double.tryParse(json['totalSales'].toString()) ?? 0.0,
      totalProducts: int.tryParse(json['totalProducts'].toString()) ?? 0,
      activeProducts: int.tryParse(json['activeProducts'].toString()) ?? 0,
      averageRating: double.tryParse(json['averageRating'].toString()) ?? 0.0,
      totalReviews: int.tryParse(json['totalReviews'].toString()) ?? 0,
      monthlyViews: int.tryParse(json['monthlyViews'].toString()) ?? 0,
      weeklySales: (json['weeklySales'] as List<dynamic>?)
              ?.map((e) => SalesData.fromJson(e))
              .toList() ??
          [],
      monthlySales: (json['monthlySales'] as List<dynamic>?)
              ?.map((e) => SalesData.fromJson(e))
              .toList() ??
          [],
      recentOrders: (json['recentOrders'] as List<dynamic>?)
              ?.map((e) => RecentOrder.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SalesData {
  final String date;
  final double sales;

  SalesData({required this.date, required this.sales});

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      date: json['date'] ?? '',
      sales: double.tryParse(json['sales'].toString()) ?? 0.0,
    );
  }
}

class RecentOrder {
  final int id;
  final String customerName;
  final String status;
  final double total;

  RecentOrder({
    required this.id,
    required this.customerName,
    required this.status,
    required this.total,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      customerName: json['customerName'] ?? 'Unknown',
      status: json['status'] ?? 'pending',
      total: double.tryParse(json['total'].toString()) ?? 0.0,
    );
  }
}