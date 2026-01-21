import 'package:dio/dio.dart';
import 'package:linyora_project/features/models/models/model_dashboard_models.dart';
import '../../../core/api/api_client.dart';


class ModelService {
  final ApiClient _apiClient = ApiClient();

  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _apiClient.get('/model/dashboard');
      return DashboardStats.fromJson(response.data);
    } catch (e) {
      return DashboardStats(); // إرجاع قيم صفرية عند الخطأ
    }
  }

  Future<List<RecentActivity>> getRecentActivity() async {
    try {
      final response = await _apiClient.get('/model/recent-activity');
      return (response.data as List).map((e) => RecentActivity.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> acceptAgreement() async {
    try {
      await _apiClient.put('/users/profile/accept-agreement');
    } catch (e) {
      throw Exception('فشل قبول الاتفاقية');
    }
  }
}