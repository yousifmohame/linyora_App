import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; // مهم لتحديد نوع الملف
import 'package:linyora_project/core/api/api_client.dart';

class VerificationService {
  final ApiClient _apiClient = ApiClient();

  Future<void> submitVerification({
    required String identityNumber,
    required File identityImage,
    required Map<String, String> socialLinks,
    required String followers,
    required String accountNumber,
    required String iban,
    required File ibanCertificate,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'identity_number': identityNumber,
        'social_links': socialLinks, // سيقوم Dio بتحويل الـ Map تلقائياً أو قد تحتاج لـ jsonEncode حسب الباك إند
        'stats': {'followers': followers}, // إرسال كـ JSON object
        'account_number': accountNumber,
        'iban': iban,
      });

      // إضافة ملف الهوية
      String idFileName = identityImage.path.split('/').last;
      formData.files.add(MapEntry(
        'identity_image',
        await MultipartFile.fromFile(identityImage.path, filename: idFileName),
      ));

      // إضافة شهادة الآيبان
      String ibanFileName = ibanCertificate.path.split('/').last;
      formData.files.add(MapEntry(
        'iban_certificate',
        await MultipartFile.fromFile(ibanCertificate.path, filename: ibanFileName),
      ));

      await _apiClient.post('/users/submit-verification', data: formData);
    } catch (e) {
      throw e; // سيتم التعامل معه في الواجهة
    }
  }
}