import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/merchant_dashboard_model.dart';

class MerchantService {
  final ApiClient _apiClient;

  MerchantService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // جلب إحصائيات لوحة التحكم
  // Endpoint: /merchants/stats (GET)
  Future<MerchantDashboardData> getDashboardStats() async {
    try {
      final response = await _apiClient.get('/merchants/stats');
      return MerchantDashboardData.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load merchant stats: $e');
    }
  }

  // الموافقة على الاتفاقية
  // Endpoint: /users/profile/accept-agreement (PUT)
  Future<void> acceptAgreement() async {
    try {
      await _apiClient.put('/users/profile/accept-agreement');
    } catch (e) {
      throw Exception('Failed to accept agreement: $e');
    }
  }

  Future<void> submitVerification({
    required String identityNumber,
    required String businessName,
    required String accountNumber, // جديد
    required String iban, // جديد
    required File identityImage,
    required File ibanCertificate, // جديد
    File? businessLicense,
    required Function(double) onProgress, // لمتابعة شريط التقدم
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'identity_number': identityNumber,
        'business_name': businessName,
        'account_number': accountNumber,
        'iban': iban,
        'identity_image': await MultipartFile.fromFile(identityImage.path),
        'iban_certificate': await MultipartFile.fromFile(ibanCertificate.path),
      });

      if (businessLicense != null) {
        formData.files.add(
          MapEntry(
            'business_license',
            await MultipartFile.fromFile(businessLicense.path),
          ),
        );
      }

      await _apiClient.post(
        '/merchants/verification', // نفس مسار الويب
        data: formData,
      );
    } catch (e) {
      // التعامل مع الأخطاء كما في الويب (استخراج الرسالة)
      if (e is DioException && e.response?.data != null) {
        throw e.response?.data['message'] ?? 'فشل تقديم الطلب';
      }
      throw e.toString();
    }
  }
}
