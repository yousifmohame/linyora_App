import '../../../core/api/api_client.dart';
import '../models/merchant_agreement_model.dart';

class MerchantAgreementsService {
  final ApiClient _apiClient = ApiClient();

  // جلب الاتفاقيات
  Future<List<MerchantAgreement>> getMyAgreements() async {
    try {
      final response = await _apiClient.get('/agreements/my-agreements');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => MerchantAgreement.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch agreements: $e');
    }
  }

  // إكمال الطلب (عندما يكون delivered)
  Future<void> completeAgreement(int id) async {
    try {
      await _apiClient.put('/agreements/$id/complete', data: {});
    } catch (e) {
      throw Exception('Failed to complete agreement: $e');
    }
  }

  // إرسال تقييم
  Future<void> reviewAgreement(int id, int rating, String comment) async {
    try {
      await _apiClient.post('/agreements/$id/review', data: {
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }
}