import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart'; // تأكد من المسار

// مودل الإحصائيات (مطابق للواجهة في React)
class SupplierStatsModel {
  final int totalProducts;
  final int totalStock;
  final int totalOrders;
  final String availableBalance;

  SupplierStatsModel({
    required this.totalProducts,
    required this.totalStock,
    required this.totalOrders,
    required this.availableBalance,
  });

  factory SupplierStatsModel.fromJson(Map<String, dynamic> json) {
    return SupplierStatsModel(
      totalProducts: int.tryParse(json['totalProducts']?.toString() ?? '0') ?? 0,
      totalStock: int.tryParse(json['totalStock']?.toString() ?? '0') ?? 0,
      totalOrders: int.tryParse(json['totalOrders']?.toString() ?? '0') ?? 0,
      availableBalance: json['availableBalance']?.toString() ?? '0.00',
    );
  }
}

class SupplierService {
  final ApiClient _apiClient = ApiClient();

  // جلب إحصائيات لوحة التحكم
  Future<SupplierStatsModel> getDashboardStats() async {
    try {
      final response = await _apiClient.get('/supplier/dashboard');
      return SupplierStatsModel.fromJson(response.data);
    } catch (e) {
      // إرجاع أصفار في حالة الخطأ لضمان عدم انهيار الواجهة
      return SupplierStatsModel(totalProducts: 0, totalStock: 0, totalOrders: 0, availableBalance: '0.00');
    }
  }
}