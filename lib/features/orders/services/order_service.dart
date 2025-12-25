import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../models/order_model.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final ApiClient _apiClient = ApiClient();

  // 1. جلب القائمة
  Future<List<OrderModel>> getMyOrders() async {
    try {
      final response = await _apiClient.get('/customer/orders');

      if (response.statusCode == 200) {
        final List data = response.data; // الباك إند يرسل مصفوفة مباشرة
        return data.map((e) => OrderModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  // 2. جلب التفاصيل
  Future<OrderModel?> getOrderDetails(int orderId) async {
    try {
      final response = await _apiClient.get('/customer/orders/$orderId');

      if (response.statusCode == 200) {
        // الباك إند يرسل: { details: {...}, items: [...] }
        // سنمرر كامل الـ JSON للموديل، والموديل الذكي الذي كتبناه سيتعامل معه
        return OrderModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching order details: $e');
      return null;
    }
  }
}
