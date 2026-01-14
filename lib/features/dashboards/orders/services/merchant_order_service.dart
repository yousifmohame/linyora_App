import 'package:dio/dio.dart';
import 'package:linyora_project/features/dashboards/orders/models/merchant_order_details_model.dart';
import '../../../../core/api/api_client.dart';
import '../models/merchant_order_model.dart';

class MerchantOrderService {
  final ApiClient _apiClient = ApiClient();

  // جلب جميع الطلبات
  Future<List<MerchantOrderSummary>> getOrders() async {
    try {
      final response = await _apiClient.get('/merchants/orders');
      final List data = response.data;
      return data.map((json) => MerchantOrderSummary.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching merchant orders: $e");
      throw e.toString();
    }
  }

  // تحديث حالة الطلب
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final response = await _apiClient.put(
        '/orders/$orderId/status',
        data: {'status': newStatus},
      );
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        throw e.response?.data['message'] ?? 'فشل تحديث الحالة';
      }
      throw e.toString();
    }
  }

  Future<MerchantOrderDetails> getOrderDetails(int orderId) async {
    try {
      final response = await _apiClient.get('/merchants/orders/$orderId');
      return MerchantOrderDetails.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw e.response?.data['message'] ?? 'فشل جلب تفاصيل الطلب';
      }
      throw e.toString();
    }
  }
}
