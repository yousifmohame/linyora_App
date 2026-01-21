import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/models/requests/models/agreement_request_model.dart';
class AgreementService {
  final ApiClient _apiClient = ApiClient();

  // جلب الطلبات
  Future<List<AgreementRequest>> getRequests() async {
    try {
      final response = await _apiClient.get('/agreements/requests');
      return (response.data as List)
          .map((e) => AgreementRequest.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('فشل جلب الطلبات');
    }
  }

  // الرد على الطلب (قبول/رفض)
  Future<void> respondToRequest(int id, String status, {String? reason}) async {
    await _apiClient.put(
      '/agreements/$id/respond',
      data: {'status': status, 'reason': reason},
    );
  }

  // البدء في التنفيذ
  Future<void> startRequest(int id) async {
    await _apiClient.put('/agreements/$id/start');
  }

  // تسليم العمل
  Future<void> deliverRequest(int id) async {
    await _apiClient.put('/agreements/$id/deliver');
  }
}