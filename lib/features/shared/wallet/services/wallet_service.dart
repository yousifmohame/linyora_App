import '../../../../core/api/api_client.dart';
import '../models/wallet_model.dart';

class WalletService {
  final ApiClient _apiClient = ApiClient();

  // جلب إحصائيات المحفظة
  Future<WalletData> getWalletData() async {
    try {
      // Endpoint الموحد الجديد
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
  Future<List<WalletTransaction>> getTransactions() async {
    try {
      final response = await _apiClient.get('/wallet/transactions?limit=50');
      List<dynamic> list = [];

      // التعامل مع هيكلية الرد { transactions: [...] }
      if (response.data is Map<String, dynamic> && response.data['transactions'] is List) {
        list = response.data['transactions'];
      } else if (response.data is List) {
        list = response.data;
      }

      return list.map((e) => WalletTransaction.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // طلب سحب رصيد
  Future<String> requestPayout(double amount) async {
    try {
      final response = await _apiClient.post(
        '/wallet/request-payout', // Endpoint الموحد
        data: {'amount': amount},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['message'] ?? 'تم تقديم الطلب بنجاح';
      }
      
      throw Exception(response.data['message'] ?? 'فشل طلب السحب');
    } catch (e) {
      // استخراج رسالة الخطأ من الباك إند إذا وجدت
      if (e is Map && e['message'] != null) {
         throw Exception(e['message']);
      }
      rethrow;
    }
  }
}