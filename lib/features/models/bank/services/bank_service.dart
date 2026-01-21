import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/models/bank/models/bank_details_model.dart';


class BankService {
  final ApiClient _apiClient = ApiClient();

  Future<BankDetails> getBankDetails() async {
    try {
      final response = await _apiClient.get('/bank/details');
      // إذا كانت البيانات null، نرجع كائن فارغ جديد
      if (response.data == null) {
        return BankDetails(
          bankName: '', accountHolderName: '', iban: '', 
          accountNumber: '', status: 'pending'
        );
      }
      return BankDetails.fromJson(response.data);
    } catch (e) {
      throw Exception('فشل جلب البيانات البنكية');
    }
  }

  Future<void> saveBankDetails(BankDetails details) async {
    await _apiClient.post('/bank/details', data: details.toJson());
  }

  Future<String> uploadCertificate(File file) async {
    String fileName = file.path.split('/').last;
    String subType = fileName.split('.').last;
    
    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType('image', subType), // أو application/pdf
      ),
    });

    final response = await _apiClient.post('/upload', data: formData);
    return response.data['imageUrl'];
  }
}