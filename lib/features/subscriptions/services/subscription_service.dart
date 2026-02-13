import '../../../core/api/api_client.dart';
import '../../../models/subscription_plan_model.dart';

class SubscriptionService {
  final ApiClient _apiClient = ApiClient(); // يستخدم التوكن تلقائياً

  // 1. جلب الخطط (ما زلنا نحتاجها لعرض الشاشة)
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final response = await _apiClient.get('/subscriptions/plans');

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => SubscriptionPlan.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching plans: $e");
      return [];
    }
  }

  // ❌ تم حذف createCheckoutSession لأننا نستخدم PaymentService الآن

  // 2. إلغاء الاشتراك
  Future<bool> cancelSubscription() async {
    try {
      // نتصل بالباك إند لإلغاء التجديد التلقائي
      final response = await _apiClient.post(
        '/payments/cancel-subscription', // تأكد أن هذا المسار يطابق الباك إند
        data: {},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error canceling subscription: $e");
      throw Exception('فشل إلغاء الاشتراك');
    }
  }
}