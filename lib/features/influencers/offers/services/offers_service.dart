import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/models/offers/models/offer_models.dart';

class OffersService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ServicePackage>> getOffers() async {
    try {
      final response = await _apiClient.get('/offers');

      print(
        "📦 Raw Response: ${response.data}",
      ); // انظر للكونسول لترى شكل البيانات

      // الحالة 1: البيانات تأتي داخل مفتاح 'data' (الأكثر شيوعاً)
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        return (response.data['data'] as List)
            .map((e) => ServicePackage.fromJson(e))
            .toList();
      }
      // الحالة 2: البيانات تأتي كقائمة مباشرة
      else if (response.data is List) {
        return (response.data as List)
            .map((e) => ServicePackage.fromJson(e))
            .toList();
      }

      return []; // هيكل غير معروف
    } catch (e) {
      print("Service Error: $e");
      throw e;
    }
  }

  Future<void> toggleStatus(
    int id,
    String currentStatus,
    Map<String, dynamic> fullData,
  ) async {
    final newStatus = currentStatus == 'active' ? 'paused' : 'active';
    // نرسل البيانات كاملة كما يتطلب الباك إند
    fullData['status'] = newStatus;
    await _apiClient.put('/offers/$id', data: fullData);
  }

  Future<void> deleteOffer(int id) async {
    await _apiClient.delete('/offers/$id');
  }

  // دوال الإنشاء والتعديل تستدعى من شاشة الفورم
  Future<void> createOffer(Map<String, dynamic> data) async {
    await _apiClient.post('/offers', data: data);
  }

  Future<void> updateOffer(int id, Map<String, dynamic> data) async {
    await _apiClient.put('/offers/$id', data: data);
  }
}
