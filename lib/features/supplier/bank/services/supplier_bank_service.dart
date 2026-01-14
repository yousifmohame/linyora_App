import 'dart:io';
import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/supplier/bank/models/supplier_bank_models.dart';
import 'package:path/path.dart' as path;

class SupplierBankService {
  final ApiClient _apiClient = ApiClient();

  // جلب التفاصيل البنكية
  Future<SupplierBankDetails?> getBankDetails() async {
    try {
      final response = await _apiClient.get('/bank/details');
      if (response.data == null) return null;
      return SupplierBankDetails.fromJson(response.data);
    } catch (e) {
      return null; // قد لا يكون لديه بيانات بعد
    }
  }

  // رفع شهادة الآيبان
  Future<String> uploadCertificate(File file) async {
    try {
      String fileName = path.basename(file.path);
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiClient.post('/upload', data: formData);
      return response.data['imageUrl'];
    } catch (e) {
      throw Exception('فشل رفع الملف');
    }
  }

  // حفظ البيانات
  Future<void> saveBankDetails(SupplierBankDetails details) async {
    try {
      await _apiClient.post('/bank/details', data: details.toJson());
    } catch (e) {
      throw Exception('فشل حفظ البيانات');
    }
  }
}