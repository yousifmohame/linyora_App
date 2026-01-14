import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/supplier/shipping/models/supplier_shipping_models.dart';


class SupplierShippingService {
  final ApiClient _apiClient = ApiClient();

  // جلب شركات الشحن
  Future<List<ShippingCompany>> getShippingCompanies() async {
    try {
      final response = await _apiClient.get('/supplier/shipping');
      return (response.data as List).map((e) => ShippingCompany.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل جلب شركات الشحن');
    }
  }

  // إضافة شركة شحن
  Future<void> addShippingCompany(String name, double cost) async {
    try {
      await _apiClient.post('/supplier/shipping', data: {
        'name': name,
        'shipping_cost': cost,
      });
    } catch (e) {
      throw Exception('فشل إضافة شركة الشحن');
    }
  }

  // تعديل شركة شحن
  Future<void> updateShippingCompany(int id, String name, double cost) async {
    try {
      await _apiClient.put('/supplier/shipping/$id', data: {
        'name': name,
        'shipping_cost': cost,
      });
    } catch (e) {
      throw Exception('فشل تعديل شركة الشحن');
    }
  }

  // حذف شركة شحن
  Future<void> deleteShippingCompany(int id) async {
    try {
      await _apiClient.delete('/supplier/shipping/$id');
    } catch (e) {
      throw Exception('فشل حذف شركة الشحن');
    }
  }
}