import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/merchant_settings_model.dart';

class SettingsService {
  final ApiClient _apiClient = ApiClient();

  Future<SettingsData> getSettings() async {
    final response = await _apiClient.get('/merchants/settings');
    return SettingsData.fromJson(response.data);
  }

  Future<void> updateSettings(SettingsData settings) async {
    await _apiClient.put('/merchants/settings', data: settings.toJson());
  }

  Future<SubscriptionData?> getSubscriptionStatus() async {
    try {
      final response = await _apiClient.get('/subscriptions/status');
      if (response.data != null) {
        return SubscriptionData.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<SubscriptionData>> getSubscriptionHistory() async {
    try {
      final response = await _apiClient.get('/subscriptions/history');
      return (response.data as List).map((e) => SubscriptionData.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> uploadImage(File file) async {
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "image": await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final response = await _apiClient.post('/upload', data: formData);
    return response.data['imageUrl'];
  }

  Future<void> cancelSubscription() async {
    await _apiClient.post('/payments/cancel-subscription');
  }
}