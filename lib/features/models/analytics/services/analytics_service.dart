import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/models/analytics/models/analytics_models.dart';


class AnalyticsService {
  final ApiClient _apiClient = ApiClient();

  Future<AnalyticsData> getAnalytics() async {
    try {
      final response = await _apiClient.get('/model/analytics');
      return AnalyticsData.fromJson(response.data);
    } catch (e) {
      throw Exception('فشل جلب التحليلات');
    }
  }
}