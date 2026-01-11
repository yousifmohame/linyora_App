import '../../../core/api/api_client.dart';
import '../models/wallet_model.dart';

class WalletService {
  final ApiClient _apiClient = ApiClient();

  // جلب بيانات المحفظة
  Future<WalletData> getWalletData() async {
    try {
      final response = await _apiClient.get('/wallet/my-wallet');
      if (response.statusCode == 200) {
        return WalletData.fromJson(response.data);
      }
      throw Exception('فشل جلب بيانات المحفظة');
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // جلب المعاملات
  // جلب المعاملات (نسخة محسنة ومصححة)
  Future<List<WalletTransaction>> getTransactions() async {
    try {
      final response = await _apiClient.get('/wallet/transactions');
      List<dynamic> list = [];

      // 🔍 2. التحقق من الهيكل (هل هو قائمة مباشرة أم داخل data؟)
      if (response.data is List) {
        list = response.data;
      } else if (response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        list = response.data['data'];
      } else if (response.data is Map<String, dynamic> &&
          response.data['transactions'] is List) {
        // الحالة الثالثة: { "transactions": [...] }
        list = response.data['transactions'];
      }

      // 🔍 3. التحويل مع التقاط الأخطاء لكل عنصر
      return list.map((e) {
        try {
          return WalletTransaction.fromJson(e);
        } catch (parseError) {
          throw parseError;
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // طلب سحب رصيد
  Future<String> requestPayout(double amount) async {
    try {
      final response = await _apiClient.post(
        '/wallet/request-payout',
        data: {'amount': amount},
      );

      // التعامل مع رسائل الخطأ من الباك إند
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'فشل طلب السحب');
      }

      return response.data['message'] ?? 'تم تقديم الطلب بنجاح';
    } catch (e) {
      // إذا كان الخطأ من نوع DioException وله رد من السيرفر
      if (e.toString().contains('message')) {
        // محاولة استخراج الرسالة (تعتمد على إعدادات Dio لديك)
        throw Exception('خطأ في الطلب');
      }
      rethrow;
    }
  }
}
