class DashboardStats {
  final int totalRequests;
  final int pendingRequests;
  final int completedAgreements;
  final double totalEarnings;
  final double monthlyEarnings;
  final int profileViews;
  final int responseRate;
  final int upcomingCollaborations;

  DashboardStats({
    this.totalRequests = 0,
    this.pendingRequests = 0,
    this.completedAgreements = 0,
    this.totalEarnings = 0.0,
    this.monthlyEarnings = 0.0,
    this.profileViews = 0,
    this.responseRate = 0,
    this.upcomingCollaborations = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalRequests: int.tryParse(json['totalRequests']?.toString() ?? '0') ?? 0,
      pendingRequests: int.tryParse(json['pendingRequests']?.toString() ?? '0') ?? 0,
      completedAgreements: int.tryParse(json['completedAgreements']?.toString() ?? '0') ?? 0,
      totalEarnings: double.tryParse(json['totalEarnings']?.toString() ?? '0') ?? 0.0,
      monthlyEarnings: double.tryParse(json['monthlyEarnings']?.toString() ?? '0') ?? 0.0,
      profileViews: int.tryParse(json['profileViews']?.toString() ?? '0') ?? 0,
      responseRate: int.tryParse(json['responseRate']?.toString() ?? '0') ?? 0,
      upcomingCollaborations: int.tryParse(json['upcomingCollaborations']?.toString() ?? '0') ?? 0,
    );
  }
}

class RecentActivity {
  final int id;
  final String type; // request, message, payment, review
  final String title;
  final String description;
  final String time;
  final bool isNew;

  RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.time,
    this.isNew = false,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'],
      type: json['type'] ?? 'request',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      time: json['time'] ?? '',
      isNew: json['isNew'] ?? false,
    );
  }
}