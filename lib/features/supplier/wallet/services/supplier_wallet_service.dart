import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/supplier/wallet/models/supplier_wallet_models.dart';

class SupplierWalletService {
  final ApiClient _apiClient = ApiClient();

  // جلب بيانات المحفظة
  Future<SupplierWallet> getWalletData() async {
    try {
      final response = await _apiClient.get('/supplier/wallet');
      return SupplierWallet.fromJson(response.data);
    } catch (e) {
      throw Exception('فشل جلب بيانات المحفظة');
    }
  }

  Future<List<WalletTransaction>> getTransactions() async {
    try {
      final response = await _apiClient.get('/wallet/transactions');
      final List list = response.data;
      return list.map((e) => WalletTransaction.fromJson(e)).toList();
    } catch (e) {
      // إرجاع قائمة فارغة في حال الخطأ بدلاً من إيقاف الشاشة
      return [];
    }
  }

  // طلب سحب رصيد
  Future<void> requestPayout(double amount) async {
    try {
      await _apiClient.post(
        '/supplier/payout-request',
        data: {'amount': amount},
      );
    } catch (e) {
      // تمرير رسالة الخطأ من السيرفر إذا وجدت
      if (e is DioException && e.response?.data['message'] != null) {
        throw Exception(e.response?.data['message']);
      }
      throw Exception('فشل إرسال طلب السحب');
    }
  }
}
