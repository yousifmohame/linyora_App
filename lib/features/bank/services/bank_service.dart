import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/bank_details_model.dart';

class BankService {
  final ApiClient _apiClient = ApiClient();

  // جلب البيانات
  Future<BankDetails> getBankDetails() async {
    try {
      final response = await _apiClient.get('/bank/details');
      if (response.statusCode == 200 && response.data != null) {
        return BankDetails.fromJson(response.data);
      }
      return BankDetails(); // إرجاع مودل فارغ في حال عدم وجود بيانات
    } catch (e) {
      // في حال 404 أو خطأ، نعيد مودل فارغ للبدء من جديد
      return BankDetails();
    }
  }

  // تحديث البيانات
  Future<void> updateBankDetails(BankDetails details) async {
    try {
      await _apiClient.post('/bank/details', data: details.toJson());
    } catch (e) {
      throw Exception('فشل حفظ البيانات البنكية');
    }
  }

  // رفع الشهادة
  Future<String?> uploadCertificate(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiClient.post('/upload', data: formData);
      // تأكد من المفتاح الذي يعيده الباك إند (imageUrl حسب كود React)
      return response.data['imageUrl'];
    } catch (e) {
      throw Exception('فشل رفع الملف');
    }
  }
}