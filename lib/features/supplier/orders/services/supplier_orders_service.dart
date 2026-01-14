import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/supplier/orders/models/supplier_order_models.dart';


class SupplierOrdersService {
  final ApiClient _apiClient = ApiClient();

  // جلب كل الطلبات
  Future<List<SupplierOrder>> getOrders() async {
    try {
      final response = await _apiClient.get('/supplier/orders');
      return (response.data as List).map((e) => SupplierOrder.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل جلب الطلبات');
    }
  }

  // جلب تفاصيل طلب واحد
  Future<OrderDetails> getOrderDetails(int id) async {
    try {
      final response = await _apiClient.get('/supplier/orders/$id');
      return OrderDetails.fromJson(response.data);
    } catch (e) {
      throw Exception('فشل جلب تفاصيل الطلب');
    }
  }

  // تحديث حالة الطلب
  Future<void> updateOrderStatus(int id, String newStatus) async {
    try {
      await _apiClient.put('/supplier/orders/$id/status', data: {'status': newStatus});
    } catch (e) {
      throw Exception('فشل تحديث الحالة');
    }
  }
}