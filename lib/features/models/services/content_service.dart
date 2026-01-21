import '../../../core/api/api_client.dart'; // استورد كلاس الـ ApiClient الخاص بك

class AgreementService {
  final ApiClient _apiClient = ApiClient();

  // 1. جلب محتوى الاتفاقية (مطابق لـ axios.get(`/content/${agreementKey}`))
  Future<Map<String, dynamic>> getAgreementContent(String key) async {
    try {
      final response = await _apiClient.get('/content/$key');
      if (response.statusCode == 200) {
        return response.data; // يتوقع {title: "...", content: "<html>..."}
      }
      throw Exception('فشل تحميل المحتوى');
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // 2. إرسال الموافقة (مطابق لـ handleAgree في React)
  Future<void> acceptAgreement() async {
    try {


      final response = await _apiClient.put(
        '/users/profile/accept-agreement',
        data: {}, // الباك إند لا يحتاج بيانات، فقط استدعاء الرابط
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('فشل التحديث: كود ${response.statusCode}');
      }
    } catch (e) {
      print("Error accepting agreement: $e");
      // تحسين رسالة الخطأ
      if (e.toString().contains("401")) {
        throw Exception("انتهت الجلسة. يرجى تسجيل الدخول.");
      } else if (e.toString().contains("404")) {
        // نادراً ما يحدث الآن لأننا عرفنا الرابط الصحيح
        throw Exception("الرابط غير صحيح (404)");
      }
      throw e;
    }
  }
}
