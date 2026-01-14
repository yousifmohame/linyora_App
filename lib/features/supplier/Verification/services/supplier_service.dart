import 'dart:io';
import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:path/path.dart'
    as path; // 1. أضف هذه المكتبة للحصول على اسم الملف

class SupplierService {
  final ApiClient _apiClient = ApiClient();

  Future<void> submitVerification({
    required String identityNumber,
    String? businessName,
    required String accountNumber,
    required String iban,
    required File identityImage,
    File? businessLicense,
    required File ibanCertificate,
  }) async {
    try {
      // 2. تجهيز البيانات
      // ملاحظة: نستخدم path.basename لجلب اسم الملف الحقيقي لضمان قبوله من السيرفر

      Map<String, dynamic> dataMap = {
        'identity_number': identityNumber,
        'business_name': businessName ?? '',
        'account_number': accountNumber,
        'iban': iban,
        'identity_image': await MultipartFile.fromFile(
          identityImage.path,
          filename: path.basename(identityImage.path),
        ),
        'iban_certificate': await MultipartFile.fromFile(
          ibanCertificate.path,
          filename: path.basename(ibanCertificate.path),
        ),
      };

      if (businessLicense != null) {
        dataMap['business_license'] = await MultipartFile.fromFile(
          businessLicense.path,
          filename: path.basename(businessLicense.path),
        );
      }

      FormData formData = FormData.fromMap(dataMap);

      print("📤 Sending Verification Data...");

      // 3. الإرسال
      final response = await _apiClient.post(
        '/supplier/verification',
        data: formData,
      );

      print("✅ Success: ${response.data}");
    } on DioException catch (e) {
      // 4. معالجة دقيقة للخطأ
      print("❌ Dio Error: ${e.message}");
      if (e.response != null) {
        print("❌ Server Response Data: ${e.response?.data}");
        print("❌ Status Code: ${e.response?.statusCode}");

        // رمي رسالة الخطأ القادمة من السيرفر لتعرض في الشاشة
        throw e.response?.data['message'] ??
            "حدث خطأ في السيرفر (${e.response?.statusCode})";
      } else {
        throw "فشل الاتصال بالسيرفر. تأكد من الإنترنت.";
      }
    } catch (e) {
      print("❌ General Error: $e");
      rethrow;
    }
  }
}
