import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../models/reel_model.dart';
import '../../../models/comment_model.dart'; // استيراد موديل التعليقات

class ReelsService {
  final ApiClient _apiClient = ApiClient();

  // جلب الريلز
  Future<List<ReelModel>> getStyleTodayReels() async {
    try {
      // Endpoint: /api/v1/reels (تأكد من الروت في الباك اند)
      // إذا كان المستخدم مسجلاً للدخول، ApiClient سيرسل التوكن تلقائياً
      // وبالتالي الباك اند سيرجع isLikedByMe = 1 or 0
      final response = await _apiClient.get('/reels');

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        List<dynamic> list = [];

        // التعامل مع صيغ الاستجابة المختلفة
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('reels')) {
            list = responseData['reels'];
          } else if (responseData.containsKey('data')) {
            list = responseData['data'];
          }
        } else if (responseData is List) {
          list = responseData;
        }

        return list.map((e) => ReelModel.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching reels: $e');
      throw Exception('Error fetching reels');
    }
  }

  // عمل لايك
  Future<bool> toggleLike(String reelId) async {
    try {
      // POST لإضافة اللايك
      await _apiClient.post('/reels/$reelId/like', data: {});
      return true;
    } catch (e) {
      // إذا فشل (مثلاً بسبب تكرار اللايك)، قد نحتاج للتحقق هل هو حذف؟
      // حسب كود الباك اند: Like له Endpoint، و Unlike له Endpoint منفصل (DELETE)
      // لذلك سنحتاج دالة منفصلة أو منطق هنا
      print('Like Error: $e');
      rethrow;
    }
  }

  // إزالة اللايك (لأن الباك اند يستخدم DELETE /reels/:id/like)
  Future<bool> removeLike(String reelId) async {
    try {
      await _apiClient.delete('/reels/$reelId/like');
      return false;
    } catch (e) {
      print('Unlike Error: $e');
      rethrow;
    }
  }

  // تسجيل المشاركة
  Future<void> trackShare(String reelId) async {
    try {
      await _apiClient.post('/reels/$reelId/share', data: {});
    } catch (e) {
      print('Share Error: $e');
    }
  }

  // جلب التعليقات (باستخدام CommentModel)
  Future<List<CommentModel>> getComments(String reelId) async {
    try {
      final response = await _apiClient.get('/reels/$reelId/comments');
      // الباك اند يرجع قائمة مباشرة: [ {id, comment, ...}, ... ]
      if (response.data is List) {
        return (response.data as List)
            .map((item) => CommentModel.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get Comments Error: $e');
      return [];
    }
  }

  // إضافة تعليق
  Future<CommentModel> addComment(String reelId, String text) async {
    try {
      final response = await _apiClient.post(
        '/reels/$reelId/comment', // لاحظ: الباك اند يستخدم /comment (مفرد) في POST
        data: {'comment': text}, // الباك اند يتوقع field اسمه comment
      );
      // الباك اند يرجع كائن التعليق الجديد
      return CommentModel.fromJson(response.data);
    } catch (e) {
      print('Add Comment Error: $e');
      rethrow;
    }
  }
}
