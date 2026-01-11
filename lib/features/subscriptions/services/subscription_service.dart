import '../../../core/api/api_client.dart';
import '../../../models/subscription_plan_model.dart';

class SubscriptionService {
  final ApiClient _apiClient = ApiClient();

  // 1. جلب الخطط الحقيقية
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final response = await _apiClient.get('/subscriptions/plans');

      if (response.statusCode == 200) {
        // البيانات تأتي مباشرة كمصفوفة حسب كود React
        return (response.data as List)
            .map((e) => SubscriptionPlan.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching plans: $e");
      return []; // إرجاع قائمة فارغة عند الخطأ
    }
  }

  // 2. إنشاء جلسة الدفع والحصول على الرابط
  Future<String?> createCheckoutSession(int planId) async {
    try {
      final response = await _apiClient.post(
        '/subscriptions/create-session',
        data: {'planId': planId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['checkoutUrl']; // الرابط الذي سنفتحه
      }
      return null;
    } catch (e) {
      print("Error creating session: $e");
      throw Exception('فشل إنشاء رابط الدفع');
    }
  }
}
