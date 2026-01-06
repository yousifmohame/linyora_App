import '../../../core/api/api_client.dart';
import '../../../models/payment_card_model.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  // 1. جلب البطاقات المحفوظة
  // GET /api/payments/methods
  Future<List<PaymentCardModel>> getCards() async {
    try {
      final response = await _apiClient.get('/payments/methods');
      return (response.data as List).map((e) => PaymentCardModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // 2. طلب "نية حفظ بطاقة" من السيرفر
  // POST /api/payments/setup-intent
  // السيرفر سيعيد لنا client_secret
  Future<String> createSetupIntent() async {
    final response = await _apiClient.post('/payments/setup-intent', data: {});
    return response.data['clientSecret'];
  }

  // 3. حذف بطاقة
  // DELETE /api/payments/methods/:id
  Future<void> deleteCard(String paymentMethodId) async {
    await _apiClient.delete('/payments/methods/$paymentMethodId');
  }
}