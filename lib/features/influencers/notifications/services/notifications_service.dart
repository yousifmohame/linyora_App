import 'package:flutter/material.dart';
import 'package:linyora_project/core/api/api_client.dart';
import '../models/notification_model.dart';

class NotificationsService {
  final ApiClient _apiClient = ApiClient();

  // جلب الإشعارات
  Future<List<NotificationModel>> getNotifications() async {
    try {
      // الـ ApiClient سيضيف التوكن تلقائياً في الهيدر
      final response = await _apiClient.get('/notifications');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      return [];
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.post('/notifications/read');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error marking all as read: $e");
      return false;
    }
  }
}