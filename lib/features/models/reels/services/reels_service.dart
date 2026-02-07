import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:linyora_project/core/api/api_client.dart'; // Adjust import to your ApiClient location
import '../models/model_reel.dart';

class ReelsService {
  final ApiClient _apiClient = ApiClient();

  // Fetch the current user's reels
  Future<List<ModelReel>> getMyReels() async {
    try {
      // Matches the endpoint used in your React code: api.get('/reels/my-reels')
      final response = await _apiClient.get('/reels/my-reels');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ModelReel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching reels: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPromotableProducts() async {
    try {
      final response = await _apiClient.get('/products/model-promotable');
      return (response.data as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // تعديل ريل (تحديث الوصف)
  // ملاحظة: الباك إند يقوم بمسح التاقات إذا لم نرسلها، لذا سنرسل الوصف فقط حالياً
  // لكي يعمل التعديل بشكل كامل مع التاقات يجب بناء واجهة اختيار المنتجات في شاشة التعديل أيضاً
  Future<bool> updateReel(int reelId, String caption) async {
    try {
      // إرسال البيانات كـ JSON (وليس FormData لأننا لا نرفع ملف فيديو جديد)
      await _apiClient.put(
        '/reels/$reelId',
        data: {
          'caption': caption,
          'tagged_products':
              "[]", // يمكن إرسال التاقات القديمة هنا للحفاظ عليها
        },
      );
      return true;
    } catch (e) {
      debugPrint("Error updating reel: $e");
      return false;
    }
  }

  // Delete a reel
  Future<bool> deleteReel(int reelId) async {
    try {
      // Matches: api.delete(`/reels/${reelToDelete}`)
      await _apiClient.delete('/reels/$reelId');
      return true;
    } catch (e) {
      print("Error deleting reel: $e");
      return false;
    }
  }
}
