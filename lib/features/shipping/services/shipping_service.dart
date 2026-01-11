import '../../../core/api/api_client.dart';
import '../models/shipping_company_model.dart';

class ShippingService {
  final ApiClient _apiClient = ApiClient();

  // جلب الشركات
  Future<List<ShippingCompany>> getCompanies() async {
    try {
      final response = await _apiClient.get('/merchants/shipping');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => ShippingCompany.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب شركات الشحن');
    }
  }

  // إضافة شركة
  Future<void> createCompany(Map<String, dynamic> data) async {
    await _apiClient.post('/merchants/shipping', data: data);
  }

  // تعديل شركة
  Future<void> updateCompany(int id, Map<String, dynamic> data) async {
    await _apiClient.put('/merchants/shipping/$id', data: data);
  }

  // حذف شركة
  Future<void> deleteCompany(int id) async {
    await _apiClient.delete('/merchants/shipping/$id');
  }

  // تغيير الحالة (تفعيل/تعطيل)
  Future<void> toggleStatus(int id, bool isActive) async {
    await _apiClient.put('/merchants/shipping/$id', data: {'is_active': isActive});
  }
}