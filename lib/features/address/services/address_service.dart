import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../models/checkout_models.dart'; // تأكد أن AddressModel هنا

class AddressService {
  final ApiClient _apiClient = ApiClient();

  // جلب العناوين
  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _apiClient.get('/users/addresses');
      return (response.data as List).map((e) => AddressModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // إضافة عنوان جديد
  Future<AddressModel> addAddress(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/users/addresses', data: data);
    return AddressModel.fromJson(response.data);
  }

  // تعديل عنوان
  Future<AddressModel> updateAddress(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/users/addresses/$id', data: data);
    return AddressModel.fromJson(response.data);
  }

  // حذف عنوان
  Future<void> deleteAddress(int id) async {
    await _apiClient.delete('/users/addresses/$id');
  }
}