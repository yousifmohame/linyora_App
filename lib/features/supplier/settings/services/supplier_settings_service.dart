import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/supplier/settings/models/supplier_settings_models.dart';

class SupplierSettingsService {
  final ApiClient _apiClient = ApiClient();

  // جلب الإعدادات
  Future<SettingsData> getSettings() async {
    try {
      final response = await _apiClient.get('/supplier/settings');
      return SettingsData.fromJson(response.data);
    } catch (e) {
      throw Exception('فشل جلب الإعدادات');
    }
  }

  // تحديث الإعدادات
  Future<void> updateSettings(SettingsData settings) async {
    try {
      await _apiClient.put('/supplier/settings', data: settings.toJson());
    } catch (e) {
      throw Exception('فشل تحديث الإعدادات');
    }
  }

  // رفع بانر المتجر
  Future<String> uploadBanner(File file) async {
    try {
      String fileName = file.path.split('/').last;
      String subType = fileName.split('.').last;

      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType('image', subType),
        ),
      });

      final response = await _apiClient.post('/upload', data: formData);
      return response.data['imageUrl'];
    } catch (e) {
      throw Exception('فشل رفع الصورة');
    }
  }
}
