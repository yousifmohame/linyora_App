class TopOffer {
  final String title;
  final double price;
  final int requestCount;

  TopOffer({required this.title, required this.price, required this.requestCount});

  factory TopOffer.fromJson(Map<String, dynamic> json) {
    return TopOffer(
      title: json['title'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      requestCount: int.tryParse(json['requestCount'].toString()) ?? 0,
    );
  }
}

class AnalyticsData {
  final double totalEarnings;
  final int completedAgreements;
  final double averageDealPrice;
  final List<TopOffer> topOffers;
  final List<Map<String, dynamic>> requestsOverTime; // {month, count}
  final Map<String, double> performanceMetrics;

  AnalyticsData({
    required this.totalEarnings,
    required this.completedAgreements,
    required this.averageDealPrice,
    required this.topOffers,
    required this.requestsOverTime,
    required this.performanceMetrics,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      totalEarnings: double.tryParse(json['totalEarnings'].toString()) ?? 0.0,
      completedAgreements: int.tryParse(json['completedAgreements'].toString()) ?? 0,
      averageDealPrice: double.tryParse(json['averageDealPrice'].toString()) ?? 0.0,
      topOffers: (json['topOffers'] as List? ?? []).map((e) => TopOffer.fromJson(e)).toList(),
      requestsOverTime: (json['requestsOverTime'] as List? ?? []).map((e) => e as Map<String, dynamic>).toList(),
      performanceMetrics: {
        'engagementRate': double.tryParse(json['performanceMetrics']?['engagementRate']?.toString() ?? '0') ?? 0,
        'profileViews': double.tryParse(json['performanceMetrics']?['profileViews']?.toString() ?? '0') ?? 0,
        'satisfactionScore': double.tryParse(json['performanceMetrics']?['satisfactionScore']?.toString() ?? '0') ?? 0,
      },
    );
  }
}