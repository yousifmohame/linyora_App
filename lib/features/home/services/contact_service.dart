import '../../../core/api/api_client.dart';

class ContactService {
  final ApiClient _apiClient = ApiClient();

  Future<void> sendMessage({
    required String name,
    required String email,
    required String phone,
    required String message,
  }) async {
    try {
      // استبدل '/contact-us' بالروت الصحيح في الباك إند الخاص بك
      await _apiClient.post('/contact', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
      });
    } catch (e) {
      // إعادة رمي الخطأ ليتم التعامل معه في الواجهة
      throw e;
    }
  }
}